class Attendance < ApplicationRecord
    belongs_to :enrollment
    
    validates_inclusion_of :attendance_type, in: %w[Present Absent Excused], message: "is not an option", allow_blank: true

    scope :for_andrew_id, -> (id){ where("andrew_id = ?", id) }
    scope :for_course, -> (id){ where("course_id = ?", id) }

end
