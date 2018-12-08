class Course < ApplicationRecord
    has_many :enrollments
    belongs_to :professor

    scope :active, -> {where(active: true)}
    scope :inactive, -> {where(active: false)}
    scope :alphabetical, -> {order(:semester_year)}
    scope :getByYear, -> (year) {where("semester_year = ?", year)}
    scope :forProfessor, -> (professorID) {where("professor_id = ?", professorID)}
    validates_format_of :semester_year, with: /\A(Spring|Fall|Summer)( )[0-9]{4}\z/, message: "should be of format Spring|Fall|Summer XXXX"
    validates_format_of :class_number, with: /\A[0-9]{2}-?[0-9]{3}\z/, message: "should be of format XX-XXX or XXXXX"

end
