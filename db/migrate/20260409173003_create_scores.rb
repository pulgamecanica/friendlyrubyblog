class CreateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :scores do |t|
      t.references :game,    null: false, foreign_key: true
      t.references :player,  null: false, foreign_key: true
      t.references :play_session, null: true, foreign_key: true

      # bigint so games using time-in-ms or distance-in-cm don't overflow.
      t.bigint :value, null: false

      # Per-score context: level reached, seed, time_ms, etc. Free-form by
      # design — the Game's scoring metadata declares what's valid.
      t.jsonb :meta, default: {}, null: false

      t.datetime :achieved_at, null: false

      t.timestamps
    end

    # Most common leaderboard queries:
    add_index :scores, [ :game_id, :value ]
    add_index :scores, [ :game_id, :achieved_at ]
    add_index :scores, [ :game_id, :player_id ]
  end
end
