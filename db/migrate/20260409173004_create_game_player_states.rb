class CreateGamePlayerStates < ActiveRecord::Migration[8.0]
  def change
    create_table :game_player_states do |t|
      t.references :game,   null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      # Free-form save data: level, coins, inventory, whatever the game wants.
      # No server-side schema — it's scoped to (game, player) and owned by
      # the game's own code.
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    add_index :game_player_states, [ :game_id, :player_id ], unique: true
  end
end
