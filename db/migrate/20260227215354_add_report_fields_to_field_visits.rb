class AddReportFieldsToFieldVisits < ActiveRecord::Migration[8.0]
  def change
    add_column :field_visits, :summary, :text
    add_column :field_visits, :report_generated_at, :datetime
    add_column :field_visits, :status, :string
  end
end
