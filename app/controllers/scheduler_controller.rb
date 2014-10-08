class SchedulerController < ApplicationController

	def ui
	end

	def search
    unless params[:mnemonic] and params[:course_number]
      render :nothing => true, :status => 404 and return
    else
      subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
      course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept
      
      render :nothing => true, :status => 404 and return unless course

      #Need a better way to get current semester
      #Maybe let user choose?
      current_semester_id = Semester.find_by(season: "Fall", year: 2014).id

      current_sections = course.sections.where(semester_id: current_semester_id)

      sections = current_sections.map do |section|
        days = []
        start_times = []
        end_times = []
        # pr section.day_times.to_a
        section.day_times.sort_by{|s| [s.start_time, s.end_time, day_to_number(s.day)] }.each do |day_time|
          days << day_time.day
          start_times << day_time.start_time
          end_times << day_time.end_time
        end

        {
          :section_id => section.sis_class_number,
          :title => "#{params[:mnemonic].upcase} #{params[:course_number]}",
          :location => section.locations.first.location,
          :days => days,
          :start_times => start_times,
          :end_times => end_times,
          :events => [],
          :allDay => false,
          :professor => section.professors.first.full_name
        }
      end

      render json: sections and return
    end
  end

  def save
    subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
    course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept
    current_user.courses << course

    render :nothing => true
  end

  def clear
    current_user.courses = []

    render :nothing => true
  end

  def saved
    subdept = Subdepartment.find_by(:mnemonic => params[:mnemonic])
    course = Course.find_by(:subdepartment_id => subdept.id, :course_number => params[:course_number]) if subdept

    render :text => current_user.courses.include?(course) ? '1' : '0'
  end

  private

  def day_to_number(day)
    days = ['Mo', 'Tu', 'We', 'Th', 'Fr']
    return days.index(day) == nil ? -1 : days.index(day)
  end

end