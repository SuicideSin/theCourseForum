class Course < ActiveRecord::Base
  belongs_to :subdepartment

  has_many :sections, :dependent => :destroy
  has_many :reviews, :dependent => :destroy

  has_and_belongs_to_many :users

  has_many :section_professors, :through => :sections
  has_many :semesters, :through => :sections
  has_many :professors, :through => :sections
  has_many :departments, :through => :subdepartments
  has_many :books, :through => :sections
  has_many :book_requirements, :through => :sections

  validates_presence_of :course_number, :subdepartment

  def professors_list
    self.professors.uniq{ |p| p.id }.sort_by{|p| p.last_name}
  end

  def mnemonic_number
    "#{Subdepartment.find_by_id(self.subdepartment_id).mnemonic} #{self.course_number}"
  end

  def book_requirements_list(status)
    self.book_requirements.where(:requirement_status => status).map{|r| r.book}.uniq
  end

  def units
    self.sections.select(:units).max.units.to_i
  end

  def self.find_by_mnemonic_number(mnemonic, number)
    Subdepartment.find_by(:mnemonic => mnemonic).courses.find_by(:course_number => number)
  end

end
