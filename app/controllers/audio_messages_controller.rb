class AudioMessagesController < ApplicationController
  before_action :set_field_visit
  before_action :set_audio_message, only: %i[destroy transcribe]

  def create
    @audio_message = @field_visit.audio_messages.build(audio_message_params)

    if @audio_message.save
      # Automatically transcribe the audio message
      TranscribeAudioJob.perform_later(@audio_message.id)

      respond_to do |format|
        format.html { redirect_to field_field_visit_path(@field_visit.field, @field_visit), notice: "Audio message uploaded successfully. Transcription in progress..." }
        format.turbo_stream
        format.json { render json: { success: true, audio_message: audio_message_json(@audio_message) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to field_field_visit_path(@field_visit.field, @field_visit), alert: "Failed to upload audio message." }
        format.json { render json: { success: false, errors: @audio_message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @audio_message.destroy

    respond_to do |format|
      format.html { redirect_to field_field_visit_path(@field_visit.field, @field_visit), notice: "Audio message deleted.", status: :see_other }
      format.turbo_stream
    end
  end

  def transcribe
    TranscribeAudioJob.perform_later(@audio_message.id)

    respond_to do |format|
      format.html { redirect_to field_field_visit_path(@field_visit.field, @field_visit), notice: "Transcription started." }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@audio_message, partial: "audio_messages/audio_message", locals: { audio_message: @audio_message }) }
    end
  end

  private

  def set_field_visit
    @field = Current.user.fields.find(params[:field_id])
    @field_visit = @field.field_visits.find(params[:field_visit_id])
  end

  def set_audio_message
    @audio_message = @field_visit.audio_messages.find(params[:id])
  end

  def audio_message_params
    params.require(:audio_message).permit(:audio_file, :duration_seconds)
  end

  def audio_message_json(audio_message)
    {
      id: audio_message.id,
      duration_seconds: audio_message.duration_seconds,
      recorded_at: audio_message.recorded_at,
      transcription: audio_message.transcription,
      audio_url: audio_message.audio_file.attached? ? url_for(audio_message.audio_file) : nil
    }
  end
end
