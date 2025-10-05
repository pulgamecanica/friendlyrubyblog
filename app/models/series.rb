class Series < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  has_many :documents, -> { order(:series_position, :published_at) }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  before_destroy :move_documents_to_uncategorized

  DEFAULT_SLUG  = "uncategorized".freeze
  DEFAULT_TITLE = "Uncategorized".freeze

  def self.uncategorized!
    find_by(slug: DEFAULT_SLUG) ||
      create!(title: DEFAULT_TITLE, description: nil)
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  private

  def move_documents_to_uncategorized
    return if slug == DEFAULT_SLUG # Don't allow deleting the uncategorized series

    uncategorized = Series.uncategorized!
    last_position = uncategorized.documents.maximum(:series_position).to_i

    documents.each_with_index do |doc, index|
      doc.update_columns(series_id: uncategorized.id, series_position: last_position + index + 1)
    end
  end
end
