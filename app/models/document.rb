class Document < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  belongs_to :author
  belongs_to :series
  has_many   :blocks, -> { order(:position) }, dependent: :destroy
  has_many   :document_tags, dependent: :destroy
  has_many   :tags, through: :document_tags

  has_paper_trail

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true
  validates :kind, inclusion: { in: %w[post note page] }

  scope :published, -> { where(published: true) }

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end
