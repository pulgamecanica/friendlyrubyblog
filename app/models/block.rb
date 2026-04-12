class Block < ApplicationRecord
  # A block belongs to EITHER a Document (blog) via document_id, OR a
  # polymorphic owner (e.g. Game) via owner_type/owner_id. Exactly one of
  # these is set for any given row. The legacy document_id path is preserved
  # so the entire blog authoring UI keeps working unchanged.
  belongs_to :document, optional: true
  belongs_to :owner, polymorphic: true, optional: true
  belongs_to :language, optional: true
  has_many :likes,    as: :likable,     dependent: :destroy

  has_paper_trail

  validates :type, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validate  :data_must_be_hash
  validate  :must_have_exactly_one_parent

  before_validation :set_position_if_blank
  before_create :shift_positions_on_insert
  before_update :shift_positions_on_update
  after_destroy :compact_positions

  after_commit :reindex_parent_search

  default_scope { order(:position) }

  # The owning record (Document or any polymorphic owner). Use this when you
  # don't care whether the block lives in the blog or the arcade.
  def parent
    owner || document
  end

  # Sibling blocks for position bookkeeping. Document-owned blocks continue to
  # scope by document_id (matching the existing index); owner-owned blocks
  # scope by the polymorphic pair.
  def sibling_blocks
    if owner_type.present?
      Block.unscoped.where(owner_type: owner_type, owner_id: owner_id)
    elsif document_id.present?
      Block.unscoped.where(document_id: document_id)
    else
      Block.none
    end
  end

  def plain_text
    "" # used by search indexing; subclasses return text
  end

  def languages
    [] # subclasses may return ["ruby"], ["js"], etc. for facet_languages
  end

  private

  def set_position_if_blank
    return if position.present?

    max_position = sibling_blocks.where.not(id: id).maximum(:position) || 0
    self.position = max_position + 1
  end

  def shift_positions_on_insert
    return unless position.present?

    # Shift all siblings at or after this position
    sibling_blocks.where("position >= ? AND id != ?", position, id || 0)
                  .update_all("position = position + 1")
  end

  def shift_positions_on_update
    return unless position_changed? && position.present?

    old_pos = position_was
    new_pos = position

    return if old_pos == new_pos

    if new_pos > old_pos
      # Moving down: shift blocks between old and new position up
      sibling_blocks.where("position > ? AND position <= ? AND id != ?", old_pos, new_pos, id)
                    .update_all("position = position - 1")
    else
      # Moving up: shift blocks between new and old position down
      sibling_blocks.where("position >= ? AND position < ? AND id != ?", new_pos, old_pos, id)
                    .update_all("position = position + 1")
    end
  end

  def compact_positions
    # Resequence all remaining siblings to eliminate gaps
    sibling_blocks.order(:position).each_with_index do |block, index|
      expected_position = index + 1
      if block.position != expected_position
        block.update_column(:position, expected_position)
      end
    end
  end

  def reindex_parent_search
    document&.reindex_search!
    owner.reindex_search! if owner.respond_to?(:reindex_search!)
  end

  def data_must_be_hash
    errors.add(:data, "must be a JSON object") unless data.is_a?(Hash)
  end

  def must_have_exactly_one_parent
    has_document = document_id.present?
    has_owner    = owner_type.present? && owner_id.present?

    if has_document && has_owner
      errors.add(:base, "block cannot belong to both a document and an owner")
    elsif !has_document && !has_owner
      errors.add(:base, "block must belong to a document or an owner")
    end
  end
end
