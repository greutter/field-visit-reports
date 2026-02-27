require "application_system_test_case"

class FieldsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email_address: "fieldtest@example.com", password: "password123")
    sign_in_as(@user)
  end

  test "user can create a field" do
    visit fields_path
    assert_text "Fields"

    click_link "Add Field"
    assert_text "Add New Field"

    fill_in "Name", with: "Test Field"

    click_button "Create Field"

    assert_text "Field was successfully created"
    assert_text "Test Field"
  end

  test "user can view field details" do
    field = @user.fields.create!(name: "Parcela Norte")

    visit field_path(field)

    assert_text "Parcela Norte"
  end

  test "user can edit a field" do
    field = @user.fields.create!(name: "Old Name")

    visit edit_field_path(field)

    fill_in "Name", with: "New Name"
    click_button "Update Field"

    assert_text "Field was successfully updated"
    assert_text "New Name"
  end

  test "user can delete a field" do
    field = @user.fields.create!(name: "To Delete")

    visit field_path(field)
    assert_text "To Delete"

    accept_confirm do
      click_on "Delete Field"
    end

    assert_text "Field was successfully deleted"
    assert_no_text "To Delete"
  end

  test "user cannot see other users fields" do
    other_user = User.create!(email_address: "other@example.com", password: "password123")
    other_field = other_user.fields.create!(name: "Other User Field")

    visit fields_path

    assert_no_text "Other User Field"
  end
end
