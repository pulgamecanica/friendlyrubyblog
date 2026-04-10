class CreatePlaySessions < ActiveRecord::Migration[8.0]
  def change
    create_table :play_sessions do |t|
      t.references :game,   null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer  :duration_ms                # populated on close
      t.boolean  :completed, default: false, null: false

      # Signed per-session token minted when the session starts; score
      # submissions must carry it so we can tie them to a real play.
      t.string :token, null: false

      t.jsonb :meta, default: {}, null: false

      t.timestamps
    end

    add_index :play_sessions, :token, unique: true
    add_index :play_sessions, [ :game_id, :started_at ]
  end
end
