# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# generates a topic name containing two words
# used for Departments, Subdepartments, Courses, and Majors
def generate_topic_name()
  num = rand(2)
  if num == 0
    Faker::Company.bs.split(" ").last(2).each{|w| w.capitalize!}.join(" ")
  else
    name = Faker::Company.catch_phrase.split(" ").last(2).each{|w| w.capitalize!}.join(" ")
    if name.split("").last == "k" || name.split("").last == "n"
      name += "s"
    end
    name
  end
end

puts "Generating default user, mst3k"

user = User.create(
  email: "mst3k@virginia.edu",
  password: "foobarbaz",
  password_confirmation: "foobarbaz",
  first_name: "Mystery",
  last_name: "Theater",
  confirmed_at: Time.now)

student = Student.create(
  grad_year: 2014,
  user_id: user.id)

puts "Generating users"

# create 20 users
20.times do
  f = Faker::Name.first_name
  l = Faker::Name.last_name
  ea = f[0] + (97 + rand(26)).chr + l[0] + rand(10).to_s + (0...2).map{ (97 + rand(26)).chr }.join

  email = ea + "@virginia.edu"

  # see if user already exists
  u = User.find_by(email: email)

  # keep generating a new user until one doesn't exist
  while u != nil
    f = Faker::Name.first_name
    l = Faker::Name.last_name
    ea = f[0] + (97 + rand(26)).chr + l[0] + rand(10).to_s + (0...2).map{ (97 + rand(26)).chr }.join
    email = ea + "@virginia.edu"
    u = User.find_by(email: email)
  end

  password = Faker::Internet.password(8)

  # create the user
  new_user = User.create(
    email: email,
    password: password,
    password_confirmation: password,
    first_name: f,
    last_name: l,
    confirmed_at: Time.now)

  Student.create(
    grad_year: 2010 + rand(7),
    user_id: new_user.id)
end

puts "Generating majors"

40.times do
  Major.find_or_create_by(name: generate_topic_name())
end

puts "Creating schools"

schools = School.create([
  {name: "College of Arts & Sciences"},
  {name: "School of Engineering & Applied Science"},
  {name: "Other Schools"}
])

puts "Generating departments"

3.times do |i|
  4.times do
    name = generate_topic_name()
    d = Department.find_by(name: name)

    while d != nil
      name = generate_topic_name()
      d = Department.find_by(name: name)
    end

    d = Department.create(name: name, school_id: i+1)
  end
end

puts "Generating subdepartments"

Department.count.times do |i|
  2.times do
    name = generate_topic_name()
    mnemonic = name.tr("-", "")[0..3].upcase
    s = Subdepartment.find_by(mnemonic: mnemonic)

    while s != nil
      name = generate_topic_name()
      mnemonic = name.tr("-", "")[0..3].upcase
      s = Subdepartment.find_by(mnemonic: mnemonic)
    end

    s = Subdepartment.create(name: name, mnemonic: name.tr("-", "")[0..3].upcase)
    if !Department.find(i+1).subdepartments.include?(s)
      Department.find(i+1).subdepartments.push(s)
    end
  end
end

puts "Generating courses"

course_words = ["Intro to", "Intermediate", "Advanced", "Special Topics in", "Studies in"]

Subdepartment.count.times do |i|
  10.times do
    Course.find_or_create_by(title: course_words[rand(5)].to_s + " " + generate_topic_name(),
                             number: 1000+rand(8000), subdepartment_id: i+1)
  end
end

puts "Generating professors"

50.times do
  f = Faker::Name.first_name
  l = Faker::Name.last_name
  ea = f[0] + (97 + rand(26)).chr + l[0] + rand(10).to_s + (0...2).map{ (97 + rand(26)).chr }.join
  Professor.find_or_create_by(first_name: f, last_name: l, email_alias: ea)
end

years = (2009..Time.now.year).to_a
seasons = ["January", "Spring", "Summer", "Fall"]

puts "Creating semesters"

years.each do |year|
  seasons.each do |season|
    p = {semester_year: year, semester_season: season}
    num = Semester.get_number(p)
    Semester.find_or_create_by(:season => season, :year => year, :number => num)
  end
end

types = ["Lecture", "Laboratory", "Discussion"]

puts "Generating sections"

Course.all.each do |c|
  3.times do

    number = 10000 + rand(10000)

    s = Section.find_by(sis_class_number: number)

    while s != nil
      number = 10000 + rand(10000)
      s = Section.find_by(sis_class_number: number)
    end

    s = Section.new(sis_class_number: number)
    s.section_number = 1 + rand(5)
    s.units = 1 + rand(4)
    s.capacity = ((rand(100)+5)*10)/10
    s.section_type = types[rand(3)]
    s.semester_id = Semester.now.id
    s.course_id = c.id
    s.save
  end
end

puts "Generating section professors"

Section.count.times do |s|
  SectionProfessor.find_or_create_by(section_id: s+1, professor_id: 1+rand(Professor.count))
end

puts "Assigning profs to empty courses"

Course.all.each do |c|
  if c.professors.empty?
    s = 0
    num = 0
    while s != nil
      num = 10000 + rand(10000)
      s = Section.find_by(sis_class_number: num)
    end
    s = Section.create(sis_class_number: num)
    s.section_number = 1 + rand(5)
    s.units = 1 + rand(4)
    s.capacity = ((rand(100)+5)*10)/10
    s.section_type = types[rand(3)]
    s.course_id = c.id
    s.semester_id = 1+rand(Semester.count)
    s.save
    SectionProfessor.find_or_create_by(section_id: s.id, professor_id: 1+rand(Professor.count))
  end
end

puts "Assigning courses to empty profs"

Professor.all.each do |p|
  if p.courses.count == 0
    SectionProfessor.find_or_create_by(section_id: 1+rand(Section.count), professor_id: p.id)
  end
end

puts "Generating reviews"

Course.all.each do |c|
  c.professors.each do |p|
    10.times do
      Review.create(course_id: c.id, professor_id: p.id, semester_id: 1+rand(Semester.count),
                    student_id: 1+rand(User.count), professor_rating: (rand*5*2).round / 2.0, enjoyability: rand(5)+1,
                    difficulty: rand(5)+1, recommend: rand(5)+1, amount_reading: (rand*5*2).round / 2.0,
                    amount_writing: (rand*5*2).round / 2.0, amount_homework: (rand*5*2).round / 2.0,
                    amount_group: (rand*5*2).round / 2.0,
                    comment: Faker::Lorem.paragraphs(1+rand(3)).join(" "))
    end
  end
end


puts "Generating grades"

Section.all.each do |s|
  for i in 1..3
    #semester = Semester.now
    semester = Semester.find_by(id: i)

    count_aplus = rand(50)
    count_a = rand(50)
    count_aminus = rand(50)

    count_bplus = rand(50)
    count_b = rand(50)
    count_bminus = rand(50)

    count_cplus = rand(50)
    count_c = rand(50)
    count_cminus = rand(50)

    count_dplus = rand(30)
    count_d = rand(30)
    count_dminus = rand(30)

    count_f = rand(10)

    count_drop = rand(5)
    count_withdraw = rand(5)
    count_other = rand(3)

    total = count_aplus + count_a + count_aminus +
            count_bplus + count_b + count_bminus +
            count_cplus + count_c + count_cminus +
            count_dplus + count_d + count_dminus +
            count_f + count_drop + count_withdraw + count_other

    gpa = (((count_aplus + count_a)*4 +
          count_aminus * 3.7 +
          count_bplus * 3.3 +
          count_b * 3 +
          count_bminus * 2.7 +
          count_cplus * 2.3 +
          count_c * 2 +
          count_cminus * 1.7 +
          count_dplus * 1.3 +
          count_d +
          count_dminus * 0.7) / (total - count_other - count_drop - count_withdraw)).round(2)

    Grade.find_or_create_by(
      section_id: s.id,
      semester_id: semester.id,
      count_aplus: count_aplus,
      count_a: count_a,
      count_aminus: count_aminus,
      count_bplus: count_bplus,
      count_b: count_b,
      count_bminus: count_bminus,
      count_cplus: count_cplus,
      count_c: count_c,
      count_cminus: count_cminus,
      count_dplus: count_dplus,
      count_d: count_d,
      count_dminus: count_dminus,
      count_f: count_f,
      count_drop: count_drop,
      count_withdraw: count_withdraw,
      count_other: count_other,
      total: total,
      gpa: gpa
    )
  end
end



days = ["Mo", "Tu", "We", "Th", "Fr"]

sm = ["00", "30"]

puts "Generating daytimes"

50.times do
  day = days[rand(5)]
  start_hour = 8 + rand(12)
  start_minute = sm[rand(2)]
  if day == "Mo" || day == "We" || day == "Fr"
    if start_minute == "00"
      end_hour = start_hour
      end_minute = "50"
    else
      end_hour = start_hour+1
      end_minute = "20"
    end
  else
    end_hour = start_hour+1
    if start_minute == "00"
      end_minute = "15"
    else
      end_minute = "45"
    end
  end

  DayTime.find_or_create_by(day: day, start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")

  case day
  when "Mo"
    DayTime.find_or_create_by(day: "We", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
    DayTime.find_or_create_by(day: "Fr", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
  when "Tu"
    DayTime.find_or_create_by(day: "Th", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
  when "We"
    DayTime.find_or_create_by(day: "Mo", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
    DayTime.find_or_create_by(day: "Fr", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
  when "Th"
    DayTime.find_or_create_by(day: "Tu", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
  when "Fr"
    DayTime.find_or_create_by(day: "Mo", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
    DayTime.find_or_create_by(day: "We", start_time: "#{start_hour}:#{start_minute}", end_time: "#{end_hour}:#{end_minute}")
  end
end

bldg = ["Hall", "Bldg", "Library"]

puts "Generating locations"

50.times do
  Location.find_or_create_by(location: Faker::Name.last_name + " " + bldg[rand(3)] + " " + rand(500).to_s)
end

puts "Creating day_times_sections"

Section.all.each do |s|

  d1 = DayTime.find(1+rand(DayTime.count))

  case d1.day
  when "Mo"
    d2 = DayTime.find_by(day: "We", start_time: d1.start_time, end_time: d1.end_time)
    d3 = DayTime.find_by(day: "Fr", start_time: d1.start_time, end_time: d1.end_time)
    l = 1+rand(Location.count)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d1.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d2.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d3.id)
  when "Tu"
    d2 = DayTime.find_by(day: "Th", start_time: d1.start_time, end_time: d1.end_time)
    l = 1+rand(Location.count)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d1.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d2.id)
  when "We"
    d2 = DayTime.find_by(day: "Mo", start_time: d1.start_time, end_time: d1.end_time)
    d3 = DayTime.find_by(day: "Fr", start_time: d1.start_time, end_time: d1.end_time)
    l = 1+rand(Location.count)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d2.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d1.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d3.id)
  when "Th"
    d2 = DayTime.find_by(day: "Tu", start_time: d1.start_time, end_time: d1.end_time)
    l = 1+rand(Location.count)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d2.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d1.id)
  when "Fr"
    d2 = DayTime.find_by(day: "Mo", start_time: d1.start_time, end_time: d1.end_time)
    d3 = DayTime.find_by(day: "We", start_time: d1.start_time, end_time: d1.end_time)
    l = 1+rand(Location.count)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d2.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d3.id)
    DayTimesSection.find_or_create_by(location_id: l, section_id: s.id, day_time_id: d1.id)
  end
end
