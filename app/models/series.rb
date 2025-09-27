class Series < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  has_many :documents, -> { order(:series_position, :published_at) }, dependent: :nullify

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true


  DEFAULT_SLUG  = "uncategorized".freeze
  DEFAULT_TITLE = "Uncategorized".freeze

  def self.uncategorized!
    find_by(slug: DEFAULT_SLUG) ||
      create!(title: DEFAULT_TITLE, description: nil)
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end
