class Professor < ApplicationRecord
    has_many :courses

    scope :alphabetical, -> { order(:last_name, :first_name) }

    validates_format_of :email, with: /\A[\w]([^@\s,;]+)@(([\w-]+\.)+(cmu\.edu))\z/, message: "is not a valid format"
    validates_presence_of :email


    def name
        return first_name + " " + last_name
    end

end
