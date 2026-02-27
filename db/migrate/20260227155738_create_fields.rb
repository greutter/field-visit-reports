class CreateFields < ActiveRecord::Migration[8.0]
  def change
    create_table :fields do |t|
      t.string :name
      t.string :location
      t.string :crop_type
      t.decimal :area_hectares
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
