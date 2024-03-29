require "ravensat"
require "nokogiri"
require "rufo"

module Swallow
  class Formatter
    def format(ast); end
  end

  class AUKFormatter < Formatter
    def format(ast)
      auk = ""
      ast.nodes.each do |node|
        auk << node.to_auk
      end
      formatter = Rufo::Formatter.new(auk)
      formatter.format
      formatter.result
    end
  end

  class CNFFormatter < Formatter
    def format(ast, ptable)
      cnf = Ravensat::InitialNode.new

      # Domain constraint
      ast.nodes.each do |node|
        node.prun(ptable)
      end

      # Domain execution
      ast.nodes.each do |node|
        tmp = node.domain_exec(ptable)
        cnf &= tmp unless tmp.is_a? Ravensat::InitialNode
      end

      # Exactly One lecture
      pvars = ptable.group_by{|i| i.lecture.name}.values.reject{|i| i.first.lecture.domain.include? DomainFrequency}

      unless pvars.empty?
        cnf &= pvars.map do |e|
          Ravensat::Claw.at_least_one e.map(&:value)
        end.reduce(:&)
        cnf &= pvars.map do |e|
          Ravensat::Claw.commander_at_most_one e.map(&:value)
        end.reduce(:&)
      end

      # Conflict between teachers
      cnf &= ptable.group_by{|i| i.instructor.name}.values.map do |e|
        e.group_by{|i| i.timeslot.name}.values.map do |l|
          Ravensat::Claw.commander_at_most_one l.map(&:value)
        end.reduce(:&)
      end.reduce(:&)

      # Conflict between rooms
      cnf &= ptable.group_by{|i| i.room.name}.values.map do |e|
        e.group_by{|i| i.timeslot.name}.values.map do |l|
          Ravensat::Claw.commander_at_most_one l.map(&:value)
        end.reduce(:&)
      end.reduce(:&)

      # Conflict Constraints
      ast.nodes.each do |node|
        cnf &= node.exec(ptable) if node.is_a? Constraint
      end

      cnf
    end
  end

  class CSVFormatter < Formatter
    def format(ast)
      csv = [] # CSV::Table
      ast.nodes.each do |node|
        csv.append [node.name] + node.domain_timeslot.period if node.domain_timeslot
      end
      # TODO: CSVクラスを使用することを検討
      csv.map(&:to_csv).reduce { |result, item| "#{result}#{item}\n" }.chomp
    end
  end

  class HTMLFormatter < Formatter
    def format(ast)
      # TODO: Nokogiriを使用する
      timeslot_constraint = ast.nodes.find{|node| node.is_a? TimeslotInitializer}.domain.constraints
      periods = timeslot_constraint.find{|i| i.is_a? DomainPeriod}.periods
      wdays = timeslot_constraint.find{|i| i.is_a? DomainWday}.wdays
      lec_periods = []

      ast.nodes.each do |node|
        next unless node.is_a? Lecture

        lecture = node.name
        period = node.domain_timeslot.timeslots if node.domain_timeslot
        lec_periods.append [lecture, period].flatten
      end
      root = Nokogiri::HTML::DocumentFragment.parse("")
      Nokogiri::HTML::Builder.with(root) do |doc|
        doc.link rel: "stylesheet", href: "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css"
        doc.div.nav.index do
          doc.h1 "Time Table"
          doc.table class: "table table-bordered" do
            doc.tr do
              doc.th nil
              wdays.each do |day|
                doc.th day
              end
            end
            periods.each do |period|
              doc.tr do
                doc.th period
                wdays.each do |day|
                  id = "#{day}#{period}"
                  td = []
                  lec_periods.each do |lec_pr|
                    td.append lec_pr.first if lec_pr.include? id
                  end
                  doc.td td.join("<br>"), id: id
                end
              end
            end
          end
        end
      end
      CGI.unescapeHTML root.to_html
    end
  end
end
