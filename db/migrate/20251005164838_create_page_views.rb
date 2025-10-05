class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views do |t|
      t.references :document, null: false, foreign_key: true, index: false
      t.string :ip_address
      t.string :country
      t.string :city
      t.string :device
      t.string :browser
      t.string :os
      t.text :referrer
      t.string :next_page
      t.text :user_agent
      t.string :unique_visitor_id
      t.string :session_id
      t.datetime :visited_at

      t.timestamps
    end

    add_index :page_views, :document_id
    add_index :page_views, :unique_visitor_id
    add_index :page_views, :session_id
    add_index :page_views, :visited_at
    add_index :page_views, :ip_address
    add_index :page_views, :country
  end
end
