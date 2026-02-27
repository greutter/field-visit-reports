require "test_helper"

class AudioMessageTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password123")
    @field = @user.fields.create!(name: "Test", location: "Location", crop_type: "Corn")
    @field_visit = @field.field_visits.create!(user: @user, visit_date: Date.current)
  end

  test "valid audio message with file" do
    audio = @field_visit.audio_messages.new(duration_seconds: 30)
    audio.audio_file.attach(io: StringIO.new("test audio"), filename: "test.webm", content_type: "audio/webm")
    assert audio.valid?
  end

  test "requires audio file" do
    audio = @field_visit.audio_messages.new(duration_seconds: 30)
    assert_not audio.valid?
    assert_includes audio.errors[:audio_file], "can't be blank"
  end

  test "sets recorded_at on create" do
    audio = @field_visit.audio_messages.new(duration_seconds: 30)
    audio.audio_file.attach(io: StringIO.new("test"), filename: "test.webm", content_type: "audio/webm")

    freeze_time do
      audio.save!
      assert_equal Time.current, audio.recorded_at
    end
  end

  test "transcription? returns true when transcription present" do
    audio = @field_visit.audio_messages.new(duration_seconds: 30, transcription: "Some text")
    audio.audio_file.attach(io: StringIO.new("test"), filename: "test.webm", content_type: "audio/webm")
    audio.save!

    assert audio.transcription?
  end

  test "transcription? returns false when transcription blank" do
    audio = @field_visit.audio_messages.new(duration_seconds: 30)
    audio.audio_file.attach(io: StringIO.new("test"), filename: "test.webm", content_type: "audio/webm")
    audio.save!

    assert_not audio.transcription?
  end

  test "chronological scope orders by recorded_at ascending" do
    audio1 = @field_visit.audio_messages.new(duration_seconds: 30, recorded_at: 1.hour.ago)
    audio1.audio_file.attach(io: StringIO.new("test1"), filename: "test1.webm", content_type: "audio/webm")
    audio1.save!

    audio2 = @field_visit.audio_messages.new(duration_seconds: 30, recorded_at: Time.current)
    audio2.audio_file.attach(io: StringIO.new("test2"), filename: "test2.webm", content_type: "audio/webm")
    audio2.save!

    messages = @field_visit.audio_messages.chronological
    assert_equal audio1, messages.first
    assert_equal audio2, messages.last
  end
end
