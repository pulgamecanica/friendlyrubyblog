class CreateDocumentTags < ActiveRecord::Migration[8.0]
  def change
    create_table :document_tags do |t|
      t.references :document, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :document_tags, [ :document_id, :tag_id ], unique: true
  end
end
