class Series < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  has_many :documents, -> { order(:series_position, :published_at) }, dependent: :nullify

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end
