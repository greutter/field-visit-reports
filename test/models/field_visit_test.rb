require "test_helper"

class FieldVisitTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password123")
    @field = @user.fields.create!(name: "Test", location: "Location", crop_type: "Corn")
  end

  test "valid field visit" do
    visit = @field.field_visits.new(user: @user, visit_date: Date.current)
    assert visit.valid?
  end

  test "requires visit date" do
    visit = @field.field_visits.new(user: @user)
    assert_not visit.valid?
    assert_includes visit.errors[:visit_date], "can't be blank"
  end

  test "default status is draft" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current)
    assert visit.draft?
  end

  test "status transitions" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current)

    visit.recording!
    assert visit.recording?

    visit.processing!
    assert visit.processing?

    visit.completed!
    assert visit.completed?
  end

  test "has many audio messages" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current)
    audio = visit.audio_messages.new(duration_seconds: 30)
    audio.audio_file.attach(io: StringIO.new("test"), filename: "test.webm", content_type: "audio/webm")
    audio.save!

    assert_includes visit.audio_messages, audio
  end

  test "total_audio_duration sums all audio messages" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current)

    2.times do |i|
      audio = visit.audio_messages.new(duration_seconds: 30 + i * 10)
      audio.audio_file.attach(io: StringIO.new("test"), filename: "test#{i}.webm", content_type: "audio/webm")
      audio.save!
    end

    assert_equal 70, visit.total_audio_duration
  end

  test "has_transcription? returns true when transcription present" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current, transcription: "Some text")
    assert visit.has_transcription?
  end

  test "has_transcription? returns false when transcription blank" do
    visit = @field.field_visits.create!(user: @user, visit_date: Date.current)
    assert_not visit.has_transcription?
  end

  test "recent scope orders by visit date descending" do
    old_visit = @field.field_visits.create!(user: @user, visit_date: 1.week.ago)
    new_visit = @field.field_visits.create!(user: @user, visit_date: Date.current)

    visits = @field.field_visits.recent
    assert_equal new_visit, visits.first
    assert_equal old_visit, visits.last
  end
end
