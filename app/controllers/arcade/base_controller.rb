class Arcade::BaseController < ApplicationController
  layout "arcade"

  # Anonymous-first: every visitor gets a Player record keyed by a signed
  # cookie. Signing in with 42 intra later "claims" this same Player.
  before_action :ensure_player

  helper_method :current_player, :intra_configured?

  private

  def current_player
    @current_player
  end

  def intra_configured?
    Intra42.configured?
  end

  def ensure_player
    token = cookies.signed[:arcade_player_token]
    player = Player.find_by(anon_token: token) if token.present?

    unless player
      player = Player.create!(anon_token: SecureRandom.hex(32))
      cookies.signed.permanent[:arcade_player_token] = {
        value: player.anon_token,
        httponly: true,
        same_site: :lax
      }
    end

    player.update_column(:last_seen_at, Time.current)
    @current_player = player
  end
end
