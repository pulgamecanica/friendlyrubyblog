class Player < ApplicationRecord
  # Arcade user. Anonymous until they sign in with 42 intra, at which point
  # intra_login + email + display_name get populated and the anon_token is
  # preserved so merges can be audited later.
  #
  # Devise/OmniAuth wiring is deliberately deferred to a later slice —
  # authentication is bolted on once the data model is proven.

  has_many :games, foreign_key: :submitter_id, dependent: :nullify, inverse_of: :submitter
  has_many :identities,           dependent: :destroy
  has_many :scores,               dependent: :destroy
  has_many :play_sessions,        dependent: :destroy
  has_many :game_player_states,   dependent: :destroy

  validates :anon_token, uniqueness: true, allow_nil: true
  validates :intra_login, uniqueness: true, allow_nil: true
  validates :email, uniqueness: true, allow_nil: true

  def anonymous?
    intra_login.blank?
  end

  def name
    display_name.presence || intra_login.presence || "anon-#{id}"
  end
end
