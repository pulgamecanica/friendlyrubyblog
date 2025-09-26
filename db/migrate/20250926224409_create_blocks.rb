class CreateBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :blocks do |t|
      t.references :document, null: false, foreign_key: true
      t.string :type
      t.integer :position
      t.jsonb :data

      t.timestamps
    end
    change_column_default :blocks, :position, from: nil, to: 1
    change_column_null    :blocks, :type, false
    add_index :blocks, [ :document_id, :position ]
    add_index :blocks, :data, using: :gin
  end
end
