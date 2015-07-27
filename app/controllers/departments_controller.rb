class DepartmentsController < ApplicationController
  # GET /departments
  # GET /departments.json
  def index
    if current_user == nil
      redirect_to root_url
      return
    end
    subdepartments = Subdepartment.all
    departments = Department.all.order(:name)
    departments.uniq {|subdepartments| subdepartments.name}
    schools = School.all.order(:name)
    artSchoolId = 1
    engrSchoolId = 2

    @artDeps = columnize(departments.select{|d| d.school_id == artSchoolId})
    @engrDeps = columnize(departments.select{|d| d.school_id == engrSchoolId })
    @otherSchools = columnize(departments.select{|d| d.school_id != artSchoolId && d.school_id != engrSchoolId })

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @departments }
    end
  end

  # GET /departments/1
  def show
    @department = Department.includes(:subdepartments => [:courses => [:overall_stats, :last_taught_semester]]).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

 
  private
    def department_params
      params.require(:department).permit(:name)
    end

end
