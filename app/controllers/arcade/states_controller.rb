class Arcade::StatesController < Arcade::BaseController
  # Per-game, per-player save state. GET returns the current blob; PUT
  # deep-merges an arbitrary JSON patch into it. Uses a singleton route
  # because there's always exactly one state row per (game, player).

  skip_before_action :verify_authenticity_token, only: :update, if: -> { request.format.json? }

  before_action :set_game

  def show
    state = GamePlayerState.find_by(game: @game, player: current_player)
    render json: { data: state&.data || {} }
  end

  def update
    patch = JSON.parse(request.body.read.presence || "{}")
    patch = {} unless patch.is_a?(Hash)

    state = GamePlayerState.upsert_for(
      game:   @game,
      player: current_player,
      patch:  patch
    )

    render json: { ok: true, data: state.data }
  rescue JSON::ParserError
    render json: { error: "invalid JSON" }, status: :bad_request
  end

  private

  def set_game
    @game = Game.visible.friendly.find(params[:game_id])
  end
end
