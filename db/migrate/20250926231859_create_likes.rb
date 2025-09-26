class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :likable, polymorphic: true, null: false, index: true
      t.string :actor_hash

      t.timestamps
    end
    add_index :likes, [ :likable_type, :likable_id, :actor_hash ], unique: true, name: "idx_likes_target_actor"
  end
end
