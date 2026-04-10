class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :submitter, foreign_key: { to_table: :players }, null: true

      t.string :title, null: false
      t.string :slug,  null: false
      t.text   :description

      # draft / pending_compile / compiling / playable / review / rejected / discarded
      t.integer :status, default: 0, null: false

      # { kind: "git"|"zip"|"manual", git_url:, git_ref:, zip_key:, ... }
      t.jsonb :source, default: {}, null: false

      # { controls:, credits:, max_score:, monotonic_score:, ... }
      t.jsonb :metadata, default: {}, null: false

      # Soft-delete so discarded games can be garbage-collected later.
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :games, :slug, unique: true
    add_index :games, :status
    add_index :games, :deleted_at
  end
end
