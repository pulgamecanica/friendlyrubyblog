class AddLanguageToCodeBlocks < ActiveRecord::Migration[8.0]
  def change
    add_reference :blocks, :language, null: true, foreign_key: true
    add_column :blocks, :interactive, :boolean, default: false, null: false
  end
end
