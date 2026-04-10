class PlaySession < ApplicationRecord
  # A single play of a game by a player. Created when the runner mounts,
  # closed when the runner disconnects (or beforeunload fires). The `token`
  # is minted here and handed to the wasm SDK so it can authenticate score
  # submissions — every score must reference an open-or-recently-closed
  # session to reduce trivial replay attacks.

  belongs_to :game
  belongs_to :player
  has_many :scores, dependent: :nullify

  validates :started_at, :token, presence: true
  validates :token, uniqueness: true

  before_validation :set_defaults, on: :create

  scope :open,   -> { where(ended_at: nil) }
  scope :closed, -> { where.not(ended_at: nil) }

  def open?
    ended_at.nil?
  end

  def close!(completed: false, meta: {})
    return if ended_at.present?

    now = Time.current
    update!(
      ended_at:    now,
      duration_ms: ((now - started_at) * 1000).round,
      completed:   completed,
      meta:        self.meta.merge(meta || {})
    )
  end

  private

  def set_defaults
    self.started_at ||= Time.current
    self.token      ||= SecureRandom.urlsafe_base64(32)
  end
end
