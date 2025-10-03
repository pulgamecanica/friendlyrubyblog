class Block < ApplicationRecord
  belongs_to :document
  belongs_to :language, optional: true
  has_many :likes,    as: :likable,     dependent: :destroy

  has_paper_trail

  validates :type, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validate  :data_must_be_hash

  before_validation :set_position_if_blank
  before_create :shift_positions_on_insert
  before_update :shift_positions_on_update
  after_destroy :compact_positions

  after_commit :reindex_parent_search

  default_scope { order(:position) }

  def plain_text
    "" # used by search indexing; subclasses return text
  end

  def languages
    [] # subclasses may return ["ruby"], ["js"], etc. for facet_languages
  end

  private

  def set_position_if_blank
    return if position.present?

    max_position = document.blocks.where.not(id: id).maximum(:position) || 0
    self.position = max_position + 1
  end

  def shift_positions_on_insert
    return unless position.present?

    # Shift all blocks at or after this position
    document.blocks.where("position >= ? AND id != ?", position, id || 0)
            .update_all("position = position + 1")
  end

  def shift_positions_on_update
    return unless position_changed? && position.present?

    old_pos = position_was
    new_pos = position

    return if old_pos == new_pos

    if new_pos > old_pos
      # Moving down: shift blocks between old and new position up
      document.blocks.where("position > ? AND position <= ? AND id != ?", old_pos, new_pos, id)
              .update_all("position = position - 1")
    else
      # Moving up: shift blocks between new and old position down
      document.blocks.where("position >= ? AND position < ? AND id != ?", new_pos, old_pos, id)
              .update_all("position = position + 1")
    end
  end

  def compact_positions
    # Resequence all remaining blocks to eliminate gaps
    document.blocks.order(:position).each_with_index do |block, index|
      expected_position = index + 1
      if block.position != expected_position
        block.update_column(:position, expected_position)
      end
    end
  end


  def reindex_parent_search
    document&.reindex_search!
  end

  def data_must_be_hash
    errors.add(:data, "must be a JSON object") unless data.is_a?(Hash)
  end
end
