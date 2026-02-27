require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_registration_path

    fill_in "Email address", with: "newuser#{Time.current.to_i}@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Sign up"

    assert_text "Welcome! Your account has been created."
    assert_current_path root_path
  end

  test "user can sign in" do
    user = User.create!(email_address: "authtest1@example.com", password: "password123")

    visit new_session_path

    fill_in "Email address", with: "authtest1@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"

    assert_current_path root_path
    assert_text "Dashboard"
  end

  test "user can sign out" do
    user = User.create!(email_address: "authtest2@example.com", password: "password123")

    visit new_session_path
    fill_in "Email address", with: "authtest2@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    assert_text "Dashboard"

    click_button "Sign out"

    assert_current_path new_session_path
  end

  test "user cannot sign in with wrong password" do
    user = User.create!(email_address: "authtest3@example.com", password: "password123")

    visit new_session_path

    fill_in "Email address", with: "authtest3@example.com"
    fill_in "Password", with: "wrongpassword"
    click_button "Sign in"

    assert_text "Try another email address or password"
  end

  test "unauthenticated user is redirected to sign in" do
    visit root_path

    assert_current_path new_session_path
  end
end
