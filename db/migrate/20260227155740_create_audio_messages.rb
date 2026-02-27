class CreateAudioMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :audio_messages do |t|
      t.references :field_visit, null: false, foreign_key: true
      t.integer :duration_seconds
      t.text :transcription
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
