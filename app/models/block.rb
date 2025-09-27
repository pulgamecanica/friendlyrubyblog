class Block < ApplicationRecord
  belongs_to :document
  has_many :likes,    as: :likable,     dependent: :destroy

  has_paper_trail

  validates :type, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :data_must_be_hash

  after_commit :reindex_parent_search

  default_scope { order(:position) }

  def plain_text
    "" # used by search indexing; subclasses return text
  end

  def languages
    [] # subclasses may return ["ruby"], ["js"], etc. for facet_languages
  end

  private

  def reindex_parent_search
    document&.reindex_search!
  end

  def data_must_be_hash
    errors.add(:data, "must be a JSON object") unless data.is_a?(Hash)
  end
end
