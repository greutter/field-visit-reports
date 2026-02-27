class RemoveExtraColumnsFromFieldVisits < ActiveRecord::Migration[8.0]
  def change
    remove_column :field_visits, :visit_date, :date
    remove_column :field_visits, :weather_conditions, :string
    remove_column :field_visits, :temperature, :integer
    remove_column :field_visits, :observations, :text
    remove_column :field_visits, :transcription, :text
    remove_column :field_visits, :summary, :text
    remove_column :field_visits, :report_generated_at, :datetime
    remove_column :field_visits, :status, :integer
  end
end
