class TranscribeAudioJob < ApplicationJob
  queue_as :default

  def perform(audio_message_id)
    audio_message = AudioMessage.find(audio_message_id)
    return unless audio_message.audio_file.attached?
    return if audio_message.transcription.present?

    transcription = LlmService.transcribe_audio(audio_message)
    audio_message.update!(transcription: transcription)
  rescue StandardError => e
    Rails.logger.error("Transcription failed for AudioMessage #{audio_message_id}: #{e.message}")
    raise
  end
end
