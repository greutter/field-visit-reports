require "test_helper"
require "minitest/mock"

class GenerateReportJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @field = fields(:one)
    @field_visit = field_visits(:one)
    @audio_message = audio_messages(:one)

    # Attach a test audio file to the fixture audio message
    @audio_message.audio_file.attach(
      io: StringIO.new("fake audio content"),
      filename: "test_audio.webm",
      content_type: "audio/webm"
    )
  end

  test "job is enqueued" do
    assert_enqueued_with(job: GenerateReportJob) do
      GenerateReportJob.perform_later(@field_visit.id)
    end
  end

  test "updates field visit with summary and status" do
    mock = Minitest::Mock.new
    mock.expect(:call, "Test report content", [ FieldVisit, String ])

    LlmService.stub(:generate_field_report, mock) do
      GenerateReportJob.perform_now(@field_visit.id)
    end

    @field_visit.reload
    assert_equal "completed", @field_visit.status
    assert_equal "Test report content", @field_visit.summary
    assert_not_nil @field_visit.report_generated_at
  end

  test "compiles transcriptions from all audio messages" do
    # Create another audio message with transcription and attached file
    audio2 = @field_visit.audio_messages.build(
      duration_seconds: 30,
      transcription: "Second audio transcription",
      recorded_at: Time.current
    )
    audio2.audio_file.attach(
      io: StringIO.new("fake audio content 2"),
      filename: "test_audio2.webm",
      content_type: "audio/webm"
    )
    audio2.save!

    generated_report = nil
    fake_generator = ->(visit, transcription) {
      generated_report = transcription
      "Generated report summary"
    }

    LlmService.stub(:generate_field_report, fake_generator) do
      GenerateReportJob.perform_now(@field_visit.id)
    end

    @field_visit.reload
    assert_equal "completed", @field_visit.status
    assert_equal "Generated report summary", @field_visit.summary
    # Check that both transcriptions were compiled
    assert_includes generated_report, "MyText"
    assert_includes generated_report, "Second audio transcription"
  end

  test "transcribes pending audio messages before generating report" do
    # Update the existing audio message to have no transcription
    @audio_message.update_column(:transcription, nil)

    fake_transcriber = ->(_audio) { "Newly transcribed text" }
    fake_generator = ->(_visit, _transcription) { "Report summary" }

    LlmService.stub(:transcribe_audio, fake_transcriber) do
      LlmService.stub(:generate_field_report, fake_generator) do
        GenerateReportJob.perform_now(@field_visit.id)
      end
    end

    @audio_message.reload
    assert_equal "Newly transcribed text", @audio_message.transcription
  end

  test "resets status on failure" do
    error_raiser = ->(_visit, _transcription) { raise StandardError, "API Error" }

    LlmService.stub(:generate_field_report, error_raiser) do
      assert_raises(StandardError) do
        GenerateReportJob.perform_now(@field_visit.id)
      end
    end

    @field_visit.reload
    assert_equal "recording", @field_visit.status
  end

  test "handles field visit with no audio messages" do
    # Create a new field visit with no audio messages
    empty_visit = @field.field_visits.create!(user: @user)

    fake_generator = ->(_visit, _transcription) { "Empty report" }

    LlmService.stub(:generate_field_report, fake_generator) do
      GenerateReportJob.perform_now(empty_visit.id)
    end

    empty_visit.reload
    assert_equal "completed", empty_visit.status
    assert_equal "Empty report", empty_visit.summary
  end

  test "sets report_generated_at timestamp" do
    freeze_time = Time.current

    Time.stub(:current, freeze_time) do
      fake_generator = ->(_visit, _transcription) { "Report" }

      LlmService.stub(:generate_field_report, fake_generator) do
        GenerateReportJob.perform_now(@field_visit.id)
      end
    end

    @field_visit.reload
    assert_not_nil @field_visit.report_generated_at
  end
end
