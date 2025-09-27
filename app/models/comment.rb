class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true, counter_cache: :comments_count

  validates :body_markdown, :actor_hash, presence: true
  validates :status, inclusion: { in: %w[visible pending hidden] }

  scope :visible, -> { where(status: "visible") }
end
