dir = "#{File.dirname(__FILE__)}/resource"

autoload :Resource, "#{dir}/base.rb"
autoload :TimeslotInitializer, "#{dir}/timeslot.rb"
autoload :Timeslot, "#{dir}/timeslot.rb"
autoload :Room, "#{dir}/room.rb"
autoload :Instructor, "#{dir}/instructor.rb"
autoload :Lecture, "#{dir}/lecture.rb"
