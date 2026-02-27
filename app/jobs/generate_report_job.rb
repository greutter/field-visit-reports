class GenerateReportJob < ApplicationJob
  queue_as :default

  def perform(field_visit_id)
    field_visit = FieldVisit.find(field_visit_id)

    # First, transcribe all audio messages that don't have transcriptions
    transcribe_pending_messages(field_visit)

    # Combine all transcriptions
    full_transcription = compile_transcription(field_visit)

    # Generate summary report using LLM
    summary = LlmService.generate_field_report(field_visit, full_transcription)

    field_visit.update!(
      summary: summary,
      status: "completed",
      report_generated_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("Report generation failed for FieldVisit #{field_visit_id}: #{e.message}")
    field_visit.update(status: :recording) # Reset to allow retry
    raise
  end

  private

  def transcribe_pending_messages(field_visit)
    field_visit.audio_messages.each do |audio_message|
      next if audio_message.transcription.present?

      transcription = LlmService.transcribe_audio(audio_message)
      audio_message.update!(transcription: transcription)
    end
  end

  def compile_transcription(field_visit)
    field_visit.audio_messages.chronological.map do |audio_message|
      timestamp = audio_message.recorded_at&.strftime("%H:%M") || "Unknown time"
      "[#{timestamp}] #{audio_message.transcription}"
    end.join("\n\n")
  end
end
