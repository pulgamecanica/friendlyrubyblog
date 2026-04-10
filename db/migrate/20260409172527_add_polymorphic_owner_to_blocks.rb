class AddPolymorphicOwnerToBlocks < ActiveRecord::Migration[8.0]
  def change
    # Blog blocks continue to use document_id. Game blocks (and any future
    # non-Document owners) use the polymorphic owner_type/owner_id columns.
    # We keep both columns populated independently — no backfill needed.
    change_column_null :blocks, :document_id, true

    add_reference :blocks, :owner, polymorphic: true, null: true, index: true
  end
end
