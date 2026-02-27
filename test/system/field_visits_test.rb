require "application_system_test_case"

class FieldVisitsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email_address: "visittest@example.com", password: "password123")
    @field = @user.fields.create!(name: "Test Field")
    sign_in_as(@user)
  end

  test "user can create a field visit" do
    visit field_path(@field)
    assert_text "Test Field"

    click_link "New Visit"
    assert_text "New Field Visit"

    click_button "Create Visit"

    assert_text "Field visit created"
  end

  test "user can view field visit details" do
    field_visit = @field.field_visits.create!(user: @user)

    visit field_field_visit_path(@field, field_visit)

    assert_text "Field Visit"
    assert_text "Audio Messages"
  end

  test "user can delete a field visit" do
    field_visit = @field.field_visits.create!(user: @user)

    visit field_field_visit_path(@field, field_visit)
    assert_text "Field Visit"

    accept_confirm do
      click_on "Delete Visit"
    end

    assert_text "Field visit was successfully deleted"
  end

  test "user sees audio recording interface" do
    field_visit = @field.field_visits.create!(user: @user)

    visit field_field_visit_path(@field, field_visit)

    assert_text "Record Audio Message"
    assert_selector "[data-controller='audio-recorder']"
  end
end
