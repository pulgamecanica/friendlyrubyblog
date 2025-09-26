class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :author

  validates :body_markdown, :actor_hash, presence: true
  validates :status, inclusion: { in: %w[visible pending hidden] }

  scope :visible, -> { where(status: "visible") }
end
