class RemoveExtraColumnsFromFields < ActiveRecord::Migration[8.0]
  def up
    # Disable foreign key checks temporarily for SQLite
    execute "PRAGMA foreign_keys = OFF"

    # SQLite workaround: recreate table without the columns
    execute <<-SQL
      CREATE TABLE fields_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name VARCHAR,
        user_id INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL
      )
    SQL
    execute "INSERT INTO fields_new (id, name, user_id, created_at, updated_at) SELECT id, name, user_id, created_at, updated_at FROM fields"
    execute "DROP TABLE fields"
    execute "ALTER TABLE fields_new RENAME TO fields"
    execute "CREATE INDEX index_fields_on_user_id ON fields (user_id)"

    # Re-enable foreign key checks
    execute "PRAGMA foreign_keys = ON"
  end

  def down
    add_column :fields, :location, :string
    add_column :fields, :crop_type, :string
    add_column :fields, :area_hectares, :decimal
    add_column :fields, :notes, :text
  end
end
