class Document < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  belongs_to :author
  belongs_to :series
  has_many   :blocks, -> { order(:position) }, dependent: :destroy
  has_many   :document_tags, dependent: :destroy
  has_many   :tags, through: :document_tags
  has_many   :comments, as: :commentable, dependent: :destroy
  has_many   :likes,    as: :likable,     dependent: :destroy

  has_paper_trail

  before_validation { self.kind ||= "post" }
  before_validation :ensure_series_assigned
  before_validation :ensure_series_position, if: -> { series_id.present? && series_position.blank? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true
  validates :kind, inclusion: { in: %w[post note page] }

  scope :published, -> { where(published: true) }

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  private

  def ensure_series_assigned
    return if series_id.present?
    self.series = Series.uncategorized!
  end

  def ensure_series_position
    # place at the end of the series if no explicit position was provided
    last = series.documents.where.not(id: id).maximum(:series_position)
    self.series_position = last.to_i + 1
  end
end
