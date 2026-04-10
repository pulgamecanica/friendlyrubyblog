class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      # Anonymous players get an opaque token stored in a signed cookie.
      # When they sign in with 42, intra_login is filled and the anon
      # identity can be "claimed" (merged).
      t.string :anon_token
      t.string :display_name
      t.string :intra_login
      t.string :email
      t.jsonb  :preferences, default: {}, null: false

      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :players, :anon_token, unique: true
    add_index :players, :intra_login, unique: true, where: "intra_login IS NOT NULL"
    add_index :players, :email,       unique: true, where: "email IS NOT NULL"
  end
end
