class AudioMessage < ApplicationRecord
  belongs_to :field_visit
  has_one_attached :audio_file

  validates :audio_file, presence: true

  before_create :set_recorded_at

  scope :chronological, -> { order(recorded_at: :asc) }

  def transcription?
    transcription.present?
  end

  def audio_url
    return nil unless audio_file.attached?
    Rails.application.routes.url_helpers.rails_blob_path(audio_file, only_path: true)
  end

  private

  def set_recorded_at
    self.recorded_at ||= Time.current
  end
end
