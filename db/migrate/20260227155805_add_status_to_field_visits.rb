class AddStatusToFieldVisits < ActiveRecord::Migration[8.0]
  def change
    add_column :field_visits, :status, :integer, default: 0, null: false
  end
end
