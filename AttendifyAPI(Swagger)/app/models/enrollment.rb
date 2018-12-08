class Enrollment < ApplicationRecord
    belongs_to :course
    belongs_to :student

    scope :alphabetical, -> { order(:andrew_id) }
    scope :active, -> {where(active: true)}
    scope :inactive, -> {where(active: false)}

    def classNumber
        return "Class number: " + course_id
    end

end
