class Like < ApplicationRecord
  belongs_to :likable, polymorphic: true, counter_cache: :likes_count

  validates :actor_hash, presence: true
  validates :actor_hash, uniqueness: { scope: [ :likable_type, :likable_id ] }
end
