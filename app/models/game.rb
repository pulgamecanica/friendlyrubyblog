class Game < ApplicationRecord
  # A submitted MLX42 game. Lives in the arcade namespace and is intentionally
  # kept separate from Document — validations, lifecycle, and UI all diverge.
  # The actual code/wasm payload is held by a single Mlx42Block owned
  # polymorphically by this Game.

  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  belongs_to :submitter, class_name: "Player", optional: true, inverse_of: :games

  # Exactly one MLX42 block per game. Ownership is polymorphic via Block#owner.
  has_many :blocks, as: :owner, dependent: :destroy
  has_one  :mlx42_block,
           -> { where(type: "Mlx42Block") },
           as: :owner,
           class_name: "Mlx42Block",
           inverse_of: :owner

  has_many :scores,             dependent: :destroy
  has_many :play_sessions,      dependent: :destroy
  has_many :game_player_states, dependent: :destroy

  has_one_attached :cover
  has_one_attached :source_archive # for zip submissions

  # Default scoring config — games override via metadata["scoring"] at
  # submission time. `direction: "high"` means higher values win (classic
  # arcade); "low" means lower wins (lap times, stroke counts).
  DEFAULT_SCORING = {
    "type"      => "points",
    "direction" => "high",
    "unit"      => "points",
    "min"       => 0,
    "max"       => 1_000_000_000, # 1B, generous sanity cap
    "monotonic" => false,
    "format"    => "{value}"
  }.freeze

  def scoring_config
    DEFAULT_SCORING.merge(metadata.to_h["scoring"].to_h)
  end

  enum :status, {
    draft:           0,
    pending_compile: 1,
    compiling:       2,
    playable:        3,
    review:          4,
    rejected:        5,
    discarded:       6
  }

  scope :visible,    -> { where(deleted_at: nil) }
  scope :listed,     -> { visible.where(status: :playable) }

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  # Placeholder — arcade search indexing comes in a later slice. Defined so
  # Block#reindex_parent_search can call it without conditionals once games
  # participate in search.
  def reindex_search!
    # no-op for now
  end

  def soft_delete!
    update!(deleted_at: Time.current, status: :discarded)
  end

  def compiled?
    mlx42_block&.compiled?
  end
end
