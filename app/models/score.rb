class Score < ApplicationRecord
  # A leaderboard entry. Validated against the owning Game's scoring metadata
  # (see Game#scoring_config) so each game's rules are declared in one place.

  belongs_to :game
  belongs_to :player
  belongs_to :play_session, optional: true

  validates :value, presence: true, numericality: { only_integer: true }
  validate :value_within_bounds
  validate :session_belongs_to_same_game_and_player

  before_validation :set_achieved_at, on: :create

  # Leaderboard helper. `direction` ("high"/"low") comes from the game's
  # scoring config; we translate it to ORDER here.
  def self.leaderboard_for(game, limit: 10)
    direction = game.scoring_config["direction"] == "low" ? :asc : :desc
    where(game: game).order(value: direction, achieved_at: :asc).limit(limit)
  end

  private

  def set_achieved_at
    self.achieved_at ||= Time.current
  end

  def value_within_bounds
    return unless game

    cfg = game.scoring_config
    max = cfg["max"]
    min = cfg["min"] || 0

    if max && value > max
      errors.add(:value, "exceeds maximum allowed for this game (#{max})")
    end
    if value < min
      errors.add(:value, "is below minimum allowed for this game (#{min})")
    end
  end

  def session_belongs_to_same_game_and_player
    return unless play_session

    if play_session.game_id != game_id
      errors.add(:play_session, "is for a different game")
    end
    if play_session.player_id != player_id
      errors.add(:play_session, "is for a different player")
    end
  end
end
