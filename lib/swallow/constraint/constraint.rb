require "active_support/all"

class Constraint
  def initialize
    @lectures
  end

  def lectures(*lecs)
    @lectures = lecs
  end

  def to_auk
    <<~AUK
      #{self.class.name.underscore} do
        lectures #{@lectures.map { |i| %("#{i}") }.join(",")}
      end

    AUK
  end

  def domain_period; end

  def domain_exec(_ptable)
    Ravensat::InitialNode.new
  end

  def prun(ptable); end

  alias name class
end

class SameStart < Constraint
end

class SameTime < Constraint
end

class DifferentTime < Constraint
end

class SameDays < Constraint
end

class DifferentDays < Constraint
end

class SameWeeks < Constraint
end

class DifferentWeeks < Constraint
end

class SameRoom < Constraint
end

class DifferentRoom < Constraint
end

class Overlap < Constraint
  def exec(ptable)
    # ptable.group_by(&:period).values.map do |e|
    #   e.select { |i| @lectures.include? i.lecture.name }.map(&:value)
    # end.reduce(:&)
  end
end
# cnf &= ptable.group_by{|i| i.lecture.name}.values.map do |e|
#   Ravensat::Claw.alo e.map(&:value)
# end.reduce(:&)

class NotOverlap < Constraint
  def exec(ptable)
    ptable.group_by { |i| i.timeslot.name }.values.map do |e|
      Ravensat::Claw.commander_at_most_one e.select { |i| @lectures.include? i.lecture.name }.map(&:value)
    end.reduce(:&)
  end
end

class SameAttendees < Constraint
end

class Precedence < Constraint
end

class WorkDay < Constraint
end

class MinGap < Constraint
end

class MaxDays < Constraint
end

class MaxDayLoad < Constraint
end

class MaxBreaks < Constraint
end

class MaxBlock < Constraint
end
