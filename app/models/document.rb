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
  has_many   :page_views, dependent: :destroy

  has_one_attached :portrait

  has_paper_trail

  before_validation { self.kind ||= "post" }
  before_validation :ensure_series_assigned
  before_validation :ensure_series_position, if: -> { series_id.present? && series_position.blank? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true
  validates :kind, inclusion: { in: %w[post note page] }

  after_commit :reindex_search!, on: [ :create, :update ]

  scope :published, -> { where(published: true) }
  scope :posts, -> { where(kind: "post") }
  scope :notes, -> { where(kind: "note") }
  scope :pages, -> { where(kind: "page") }

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def reindex_search!
    return if destroyed? || marked_for_destruction?

    parts = []
    langs = []

    blocks.find_each do |b|
      # plain_text and languages are tiny helpers on Block subclasses
      parts << (b.respond_to?(:plain_text) ? b.plain_text.to_s : "")
      if b.respond_to?(:languages)
        langs.concat(Array(b.languages).compact.map(&:downcase))
      end
    end

    update_columns(
      search_text: parts.join("\n\n").squish,
      facet_languages: langs.compact.map(&:downcase).uniq.sort
    )
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
