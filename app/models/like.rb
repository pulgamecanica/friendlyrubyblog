class Like < ApplicationRecord
  belongs_to :likable, polymorphic: true

  validates :actor_hash, presence: true
  validates :actor_hash, uniqueness: { scope: [ :likable_type, :likable_id ] }
end
