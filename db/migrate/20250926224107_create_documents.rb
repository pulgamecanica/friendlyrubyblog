class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :kind
      t.string :title
      t.string :slug
      t.text :description
      t.references :author, null: false, foreign_key: true
      t.boolean :published
      t.datetime :published_at
      t.references :series, null: false, foreign_key: true
      t.integer :series_position
      t.jsonb :metadata, null: false, default: {}
      t.text :search_text, null: false, default: ""
      t.tsvector :search_vector
      t.string :facet_languages, array: true, null: false, default: []

      t.timestamps
    end
    add_index :documents, :slug, unique: true
    add_index :documents, :title, using: :gin, opclass: :gin_trgm_ops
    add_index :documents, :search_vector, using: :gin
    add_index :documents, :facet_languages, using: :gin
  end
end
