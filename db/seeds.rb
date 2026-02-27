# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating demo user..."
user = User.find_or_create_by!(email_address: "demo@agrofield.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "Creating sample fields..."
fields_data = [
  { name: "Parcela Norte" },
  { name: "Campo El Molino" },
  { name: "Lote Sur" }
]

fields_data.each do |field_attrs|
  user.fields.find_or_create_by!(name: field_attrs[:name])
end

puts "Creating sample field visits..."
user.fields.each do |field|
  field.field_visits.find_or_create_by!(user: user)
end

puts "Seed completed!"
puts "Demo user: demo@agrofield.com / password123"
