class SchedulerController < ApplicationController

  require 'icalendar/tzinfo'

	def manual
    # calls export_ics if .ics is appended to the url (otherwise no special action)
    respond_to do |format|
      format.html
      format.ics {export_ics}
    end
	end

  def scheduler
    respond_to do |format|
      format.html
      format.ics {export_ics}
    end
  end

  def index
    render :json => current_user.schedules
  end

  def destroy
    current_user.schedules = []
    render :nothing => true
  end

  # Old method of getting sections from the database
  # Does not break them up by type (discussion, lab, lecture)
	def search_sections
    # return an error if the search was able to be split into mnemonic and course number
    unless params[:mnemonic] and params[:course_number]
      render :nothing => true, :status => 404 and return
    else
      # Find the subdepartment by the given mnemonic
      subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
      # Find the course by that subdepartment id and the given course number
      course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept
      # return an error if no such course was found
      render :nothing => true, :status => 404 and return unless course

      # Gets all the sections of the found course that are for the (hardcoded) fall 2014 semester
      #Need a better way to get current semester
      #Maybe let user choose?
      current_sections = course.sections.where(semester_id: Semester.find_by(season: "Fall", year: 2014).id)

      # Passes the sections to a method that will convert them to javascript sections
      # Wraps the result in json for the automatic.js to use, and returns
      render json: rsections_to_jssections(current_sections) and return
    end
  end

  # Called via ajax request when enter is pressed in search
  # Returns the sections that match the search
  def search_course
    # return an error if the search was able to be split into mnemonic and course number
    unless params[:mnemonic] and params[:course_number]
      render :nothing => true, :status => 404 and return
    else
      # Find the subdepartment by the given mnemonic
      subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
      # Find the course by that subdepartment id and the given course number
      course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept
      # return an error if no such course was found
      render :nothing => true, :status => 404 and return unless course

      # semester = Semester.now
      semester = Semester.find_by(season: "Fall", year: 2015)

      # Breaks up the course's sections by type, convertubg them to javascript sections,
      # and wraps the result in json
      render :json => course.as_json.merge({
        #sets the course mnemonic from the search parameters
        :course_mnemonic => "#{params[:mnemonic].upcase} #{params[:course_number]}",
        #gets the sections of the course that are for the current semester and are lectures
        :lectures => rsections_to_jssections(course.sections.where(:semester_id => semester.id, :section_type => 'Lecture')),
        #gets the sections of the course that are for the current semester and are discussions
        :discussions => rsections_to_jssections(course.sections.where(:semester_id => semester.id, :section_type => 'Discussion')),
        #gets the sections of the course that are for the current semester and are labs
        :laboratories => rsections_to_jssections(course.sections.where(:semester_id => semester.id, :section_type => 'Laboratory')),
        # Returns units of course
        :units => course.units
      }) and return
    end
  end

  # Returns as json the current user's saved sections
  def sections
    render :json => {:success => true, :sections => rsections_to_jssections(current_user.sections)}
  end

  # Given a mnemonic and course number, add the matching course to the current user's courses (not used)
  def save_course
    subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
    course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept

    current_user.courses << course unless current_user.courses.include? course

    render :nothing => true
  end
 
  # Given section ids from the javascript, add the sections' parent courses to the current user's courses
  def save_sections
    sections = Section.find(JSON.parse(params[:sections]))
    current_user.sections = sections
    sections.each do |section|
      unless current_user.courses.include?(section.course)
        current_user.courses << section.course
      end
    end

    render :nothing => true
  end

  # Given section ids from the javascript, add the sections into the current user's sections
  def save_selections
    # Gets an array of sections with the given ids
    sections = Section.where(id: params[:sections])
    # Adds each section to current user's sections if it isn't already there
    sections.each do |section|
      unless current_user.sections.include?(section)
        current_user.sections << section
      end
    end
    render :nothing => true
  end

  # Clears the current users's saved courses (not used)
  def clear_courses
    current_user.courses = []

    render :nothing => true
  end

  def save_schedule
    schedule = current_user.schedules.create(:name => params[:name])
    schedule.sections = Section.find(JSON.parse(params[:sections]))

    render :json => {:success => true}
  end

  def show_schedules
    render :json => {:success => true, :results => current_user.schedules.map { |schedule|
      schedule.as_json.merge(:sections => rsections_to_jssections(schedule.sections))
    }}
  end

  # Given an 2D array of section ids by type (lab, discussion, lecture)
  # generates possible schedules that are without conflicts
  def generate_schedules
    # if sections were passed,
    if params[:course_sections]
      # for each type of section in the array
      course_sections = JSON.parse(params[:course_sections]).map do |course|
        # use its id to find the corresponding model object and replace it with that
        course.map do |section_id|
          Section.find(section_id)
        end
      end 
    end

    # Permute through the array of arrays to generate all possible combinations of schedules
    # http://stackoverflow.com/questions/5582481/creating-permutations-from-a-multi-dimensional-array-in-ruby
    if course_sections.count == 1
      schedules = course_sections.flatten.map do |section|
        [section]
      end
    elsif course_sections.count == 0
      schedules = []
    else
      schedules = course_sections.inject(&:product).map(&:flatten)
    end

    # Examine each schedule and only keep the ones that do not conflict
    # If a schedule has conflicts - is turned into nil and removed in Array.compact
    valid_schedules = schedules.map do |sections|
      schedule = []
      sections.each do |section|
        if conflicts(schedule, section)
          break
        else
          schedule << section
        end
      end
      sections.count == schedule.count ? rsections_to_jssections(schedule) : nil
    end.compact
    valid_schedules.map!.with_index do |schedule, index|
      {
        name: "Schedule \##{index + 1}",
        sections: schedule
      }
    end
    render :json => valid_schedules and return
  end

  private

  # Converts rails sections to javascript sections
  def rsections_to_jssections(sections)
    # for each of the sections,
    # replace it with an object with its corresponding fields
    sections.map do |section|
      # Three blank arrays to be 
      # The days the the section is taught
      days = []
      # its start and end times
      start_times = []
      end_times = []

      # For each of the sections day_times, 
      # sort them by start time, then end tie, then day of the week,
      # then populate the arrays above the corresponding information
      section.day_times.sort_by{|s| [s.start_time, s.end_time, day_to_number(s.day)] }.each do |day_time|
        days << day_time.day
        startTime = day_time.start_time
        endTime = day_time.end_time
        if startTime.length == 4
          startTime = "0" + startTime
        end
        if endTime.length == 4
          endTime = "0" + endTime
        end
        start_times << startTime
        end_times << endTime
      end
      # Make this info, as well as other various fields, part of a json object
      start_times[0] == "" ? nil : {
        :section_id => section.id,
        :title => "#{section.course.subdepartment.mnemonic} #{section.course.course_number}",
        :location => section.locations.empty? ? 'NA' : section.locations.first.location,
        :days => days,
        :start_times => start_times,
        :end_times => end_times,
        :events => [],
        :allDay => false,
        :professor => section.professors.first.full_name,
        :sis_id => section.sis_class_number
      }
    end.compact
  end

  # Given a schedule being built, and a section to consider,
  # checks if it conflits with any other previously added sections
  # or if it conflicts with any optimization parameters (no mornings classes, no friday classes, etc)
  # returning false means there are no conflicts and the section will be added
  def conflicts(partial_schedule, new_section)
    # If a student wants no morning classes,
    if params[:mornings] == 'true'
      # check if any of the section's day times start before 10am 
      new_section.day_times.each do |day_time|
        if day_time.start_time.sub(':', '.').to_f < 10
          return true
        end
      end
    end
    # If a student wants no evening classes,
    if params[:evenings] == 'true'
      # check if any of the section's day times end after 5pm
      new_section.day_times.each do |day_time|
        if day_time.end_time.sub(':', '.').to_f > 17
          return true
        end
      end
    end
    # If a student wants no Friday classes,
    if params[:fridays] == 'true'
      new_section.day_times.each do |day_time|
        # check if any of the section's day times is a Friday
        if day_time.day = 'Fr'
          return true
        end
        # or if any classes on thursday end late at night (for a thirsty thursday)
        if day_time.day == 'Th' && day_time.end_time.sub(':','.').to_f > 19
          return true
        end
      end
    end

    # Other possible optimizations??
    # would need to include this info in sections
    # if params[:good] == 'true'
    #   return new_section.rating > 2.5
    # end
    # if params[:easy] == 'true'
    #   return new_section.average_gpa > 3.4
    # end

    # Lastly, check if any previous sections part of the schedule overlap with the new one
    partial_schedule.each do |section|
      if section.conflicts?(new_section)
        return true
      end
    end
    return false
  end

  # Given a day in the form 'Mo', 'Tu', etc
  # return a number corresponding to the day of the week
  # fullCalendar requires this format?
  def day_to_number(day)
    days = ['Mo', 'Tu', 'We', 'Th', 'Fr']
    return days.index(day) == nil ? -1 : days.index(day)
  end

  # takes a section, and turns each of its days into an iCal event
  # stores those events into an array 
  # each event (day) will be repeated weekly
  def render_ical_event(section)
    
      events = [] #array to hold all the days in a section (MWF are 3 separate events that repeat weekly)
      tzid = "America/New_York" # time zone

      # loop through each day of the section
      section.day_times.sort_by{|s| [s.start_time, s.end_time, day_to_number(s.day)] }.each do |day_time|

        event = Icalendar::Event.new

        # Create the start and end DateTimes
        firstMondayOfClasses = 12 # classes start monday Jan 12, 2015 
        eventDate = firstMondayOfClasses + day_to_number(day_time.day) # add the day of the week to the first day to get the date

        # Break the start_time format (18:00) into hour and minutes
        startTimeString = day_time.start_time
        startTimeString[":"] = "" #remove the colon
        (startTimeString.to_i >= 1000) ? startingHour = startTimeString.slice(0,2) : startingHour = startTimeString.slice(0, 1) #character size of hour will vary
        startingMinutes = startTimeString.slice(startTimeString.size-2, 2) # the minutes are always the last two chars

        # Do the same for the end time
        endTimeString = day_time.end_time
        endTimeString[":"] = ""
        (endTimeString.to_i >= 1000) ? endingHour = endTimeString.slice(0,2) : endingHour = endTimeString.slice(0,1)
        endingMinutes = endTimeString.slice(endTimeString.size-2, 2)

        # Construct DateTime objects using the above values
        event_start = DateTime.new(2015, 1, eventDate, startingHour.to_i, startingMinutes.to_i, 1) #seconds have to be something otherwise it doesn't add? (weird af)
        event_end = DateTime.new(2015, 1, eventDate, endingHour.to_i, endingMinutes.to_i, 1)

        # assign this to event's start and end fields along with the timezone
        event.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => tzid
        event.dtend   = Icalendar::Values::DateTime.new event_end, 'tzid' => tzid

        #other event fields
        event.summary = "#{section.course.subdepartment.mnemonic} #{section.course.course_number}"
        event.description = "#{section.course.subdepartment.mnemonic} #{section.course.course_number}"
        event.location = section.locations.first.location
        event.rrule = "FREQ=WEEKLY;UNTIL=20150428T000000Z" #repeats once a week until hardcoded course end date (could do COUNT= if num occurences is known)

        #other unused fields
        #event.klass
        #event.created
        #event.last_modified
        #event.uid
        #event.add_comment = "created from theCourseForum.com!?"

        #adds the day for that section into an array
        events << event

      end 
      
      return events
  end

  # creates a calendar. loops through the saved sections.
  # turns each one as an ical event using render_ical_event
  # adds them to the calendar. publishes that calendar as a file
  def export_ics
    @calendar = Icalendar::Calendar.new
    # tzid = "America/New_York"
    # tz = TZInfo::Timezone.get tzid
    # timezone = tz.ical_timezone event.dtstart
    # @calendar.add_timezone timezone
    courses = current_user.courses
    courses.each do |course|
      sections = course.sections
      sections.each do |section|
        events = render_ical_event(section)
        events.each do |event|
          @calendar.add_event(event)
        end  
      end
    end

    @calendar.publish
    headers['Content-Type'] = "text/calendar; charset=UTF-8"
    render :text => @calendar.to_ical

  end


end  