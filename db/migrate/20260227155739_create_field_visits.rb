class CreateFieldVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :field_visits do |t|
      t.references :field, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :visit_date
      t.string :weather_conditions
      t.integer :temperature
      t.text :observations
      t.text :transcription
      t.text :summary
      t.datetime :report_generated_at

      t.timestamps
    end
  end
end
