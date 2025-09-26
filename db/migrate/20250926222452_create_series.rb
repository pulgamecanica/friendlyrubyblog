class CreateSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :series do |t|
      t.string :title
      t.string :slug
      t.text :description

      t.timestamps
    end
    add_index :series, :slug, unique: true
  end
end
