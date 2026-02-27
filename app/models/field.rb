class Field < ApplicationRecord
  belongs_to :user
  has_many :field_visits, dependent: :destroy

  validates :name, presence: true

  def to_s
    name
  end
end
