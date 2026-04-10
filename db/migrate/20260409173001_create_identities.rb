class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.references :player, null: false, foreign_key: true
      t.string :provider, null: false   # "intra42", later maybe "github", etc.
      t.string :uid, null: false        # provider-side user id
      t.jsonb  :raw_info, default: {}, null: false

      t.timestamps
    end

    add_index :identities, [ :provider, :uid ], unique: true
  end
end
