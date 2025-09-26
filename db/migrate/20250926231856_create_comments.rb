class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false, index: true
      t.string :name
      t.string :email
      t.string :website
      t.text :body_markdown

      t.string :status, null: false, default: "visible"   # "visible" | "pending" | "hidden"

      t.string :actor_hash, null: false
      t.string  :ip_hash
      t.string  :user_agent_hash
      t.float   :spam_score, null: false, default: 0.0

      t.bigint :parent_id

      t.timestamps
    end
    add_index :comments, :parent_id
    add_index :comments, :actor_hash
  end
end
