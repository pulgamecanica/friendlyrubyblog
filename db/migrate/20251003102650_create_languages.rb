class CreateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :languages do |t|
      t.string :name, null: false
      t.string :extension, null: false
      t.string :executable_command
      t.boolean :interactive, default: false, null: false

      t.timestamps
    end

    add_index :languages, :name, unique: true
    add_index :languages, :extension
  end
end
