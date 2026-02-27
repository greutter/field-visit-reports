class FieldVisit < ApplicationRecord
  belongs_to :field
  belongs_to :user
  has_many :audio_messages, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }

  def total_audio_duration
    audio_messages.sum(:duration_seconds)
  end
end
