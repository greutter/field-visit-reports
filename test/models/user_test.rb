require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert user.valid?
  end

  test "requires email" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email" do
    User.create!(email_address: "test@example.com", password: "password123")
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "normalizes email to lowercase" do
    user = User.create!(email_address: "TEST@EXAMPLE.COM", password: "password123")
    assert_equal "test@example.com", user.email_address
  end

  test "requires minimum password length" do
    user = User.new(email_address: "test@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "has many fields" do
    user = User.create!(email_address: "test@example.com", password: "password123")
    field = user.fields.create!(name: "Test", location: "Here", crop_type: "Corn")
    assert_includes user.fields, field
  end

  test "has many field visits" do
    user = User.create!(email_address: "test@example.com", password: "password123")
    field = user.fields.create!(name: "Test", location: "Here", crop_type: "Corn")
    visit = field.field_visits.create!(user: user, visit_date: Date.current)
    assert_includes user.field_visits, visit
  end
end
