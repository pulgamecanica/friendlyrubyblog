class AddCountersToDocumentsAndBlocks < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :comments_count, :integer, null: false, default: 0
    add_column :documents, :likes_count,    :integer, null: false, default: 0

    # blocks
    add_column :blocks, :comments_count, :integer, null: false, default: 0
    add_column :blocks, :likes_count,    :integer, null: false, default: 0
  end
end
