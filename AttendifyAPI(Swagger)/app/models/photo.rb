class Photo < ApplicationRecord
    belongs_to :student

    validates_presence_of :andrew_id


    scope :for_andrew_id, -> (id){ where("andrew_id = ?", id) }
end
