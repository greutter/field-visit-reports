require "test_helper"

class FieldTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "test@example.com", password: "password123")
  end

  test "valid field" do
    field = @user.fields.new(name: "Test Field", location: "Location", crop_type: "Corn")
    assert field.valid?
  end

  test "requires name" do
    field = @user.fields.new(location: "Location", crop_type: "Corn")
    assert_not field.valid?
    assert_includes field.errors[:name], "can't be blank"
  end

  test "requires location" do
    field = @user.fields.new(name: "Test", crop_type: "Corn")
    assert_not field.valid?
    assert_includes field.errors[:location], "can't be blank"
  end

  test "requires crop type" do
    field = @user.fields.new(name: "Test", location: "Location")
    assert_not field.valid?
    assert_includes field.errors[:crop_type], "can't be blank"
  end

  test "area must be positive" do
    field = @user.fields.new(name: "Test", location: "Location", crop_type: "Corn", area_hectares: -5)
    assert_not field.valid?
    assert_includes field.errors[:area_hectares], "must be greater than 0"
  end

  test "has many field visits" do
    field = @user.fields.create!(name: "Test", location: "Location", crop_type: "Corn")
    visit = field.field_visits.create!(user: @user, visit_date: Date.current)
    assert_includes field.field_visits, visit
  end

  test "to_s returns formatted name" do
    field = @user.fields.create!(name: "North Field", location: "Buenos Aires", crop_type: "Soja")
    assert_equal "North Field - Soja (Buenos Aires)", field.to_s
  end
end
