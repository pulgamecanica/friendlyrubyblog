class Arcade::PlaySessionsController < Arcade::BaseController
  # These are JSON endpoints hit by the Stimulus arcade bridge. They do NOT
  # render HTML and they carry the CSRF token from the same-origin page,
  # which is sufficient since we only accept same-origin fetches.

  skip_before_action :verify_authenticity_token, only: [ :create, :update, :close ], if: -> { request.format.json? }
  # sendBeacon sends with content-type text/plain;charset=UTF-8, so also
  # skip CSRF when the content type looks like a beacon payload.
  skip_before_action :verify_authenticity_token, only: [ :close ],
    if: -> { request.content_type&.include?("text/plain") || request.content_type&.include?("application/json") }

  before_action :set_game

  def create
    session = PlaySession.create!(
      game:   @game,
      player: current_player,
      meta:   { "user_agent" => request.user_agent }
    )

    render json: {
      session_id: session.id,
      token:      session.token,
      scoring:    @game.scoring_config
    }
  end

  def update
    session = @game.play_sessions.find(params[:id])
    head :forbidden and return unless session.player_id == current_player.id

    session.close!(
      completed: ActiveModel::Type::Boolean.new.cast(params[:completed]),
      meta:      params[:meta].present? ? params[:meta].permit(params[:meta].keys).to_h : {}
    )

    render json: { ok: true, duration_ms: session.duration_ms }
  end

  # POST endpoint for sendBeacon (which can only POST, not PATCH).
  def close
    session = @game.play_sessions.find(params[:id])
    head :forbidden and return unless session.player_id == current_player.id

    # sendBeacon body comes as raw JSON or text/plain — parse either way.
    body = begin
      JSON.parse(request.body.read)
    rescue
      {}
    end

    session.close!(
      completed: ActiveModel::Type::Boolean.new.cast(body["completed"]),
      meta:      body["meta"] || {}
    )

    head :ok
  end

  private

  def set_game
    @game = Game.visible.friendly.find(params[:game_id])
  end
end
