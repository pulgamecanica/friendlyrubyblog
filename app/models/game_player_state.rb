class GamePlayerState < ApplicationRecord
  # One row per (game, player). Stores the player's save data for that game
  # as free-form JSON. No server-side schema: each game is free to define its
  # own save format.

  belongs_to :game
  belongs_to :player

  validates :game_id, uniqueness: { scope: :player_id }
  validate :data_must_be_hash

  def self.upsert_for(game:, player:, patch:)
    record = find_or_initialize_by(game: game, player: player)
    record.data = (record.data || {}).deep_merge(patch.to_h)
    record.save!
    record
  end

  private

  def data_must_be_hash
    errors.add(:data, "must be a JSON object") unless data.is_a?(Hash)
  end
end
