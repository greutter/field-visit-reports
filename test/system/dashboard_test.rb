require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email_address: "dashtest@example.com", password: "password123")
    sign_in_as(@user)
  end

  test "dashboard shows stats" do
    visit root_path
    assert_text "Dashboard"

    assert_text "Total Fields"
    assert_text "Total Visits"
  end

  test "dashboard shows recent field visits" do
    field = @user.fields.create!(name: "Test Field")
    field_visit = field.field_visits.create!(user: @user)

    visit root_path
    assert_text "Dashboard"

    assert_text "Recent Field Visits"
    assert_text "Test Field"
  end

  test "dashboard shows user fields" do
    @user.fields.create!(name: "Field One")
    @user.fields.create!(name: "Field Two")

    visit root_path
    assert_text "Dashboard"

    assert_text "Your Fields"
    assert_text "Field One"
    assert_text "Field Two"
  end

  test "dashboard shows empty state when no fields" do
    visit root_path
    assert_text "Dashboard"

    assert_text "No fields yet"
    assert_link "Add a Field"
  end

  test "user can navigate to fields from dashboard" do
    visit root_path
    assert_text "Dashboard"

    click_link "Fields", match: :first

    assert_current_path fields_path
  end
end
