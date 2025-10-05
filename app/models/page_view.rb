class PageView < ApplicationRecord
  belongs_to :document

  validates :document_id, :visited_at, presence: true

  scope :recent, -> { order(visited_at: :desc) }
  scope :unique_visitors, -> { select(:unique_visitor_id).distinct }
  scope :by_country, ->(country) { where(country: country) }
  scope :this_week, -> { where("visited_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("visited_at >= ?", 1.month.ago) }
  scope :today, -> { where("visited_at >= ?", Time.current.beginning_of_day) }

  # Check if this is a unique visit for this visitor
  def unique_visit?
    PageView.where(
      document_id: document_id,
      unique_visitor_id: unique_visitor_id
    ).where("visited_at < ?", visited_at).none?
  end
end
