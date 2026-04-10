class Arcade::ScoresController < Arcade::BaseController
  skip_before_action :verify_authenticity_token, only: :create, if: -> { request.format.json? }

  before_action :set_game

  # POST /arcade/games/:game_id/scores
  #
  # Body: { value: Integer, meta: {...}, session_token: "..." }
  #
  # The session_token is minted by #create on PlaySessionsController and
  # handed to the wasm SDK when the runner mounts. We verify that (a) it
  # matches an open session for the same (game, player), and (b) for
  # monotonic games, the new score beats the session's previous best.
  def create
    session = @game.play_sessions.find_by(token: params[:session_token])

    unless session && session.player_id == current_player.id && session.open?
      render json: { error: "invalid or closed session" }, status: :unprocessable_entity
      return
    end

    # Monotonic guard: for games where a session should produce exactly one
    # "final" score, reject regressions against the session's current best.
    if @game.scoring_config["monotonic"]
      direction = @game.scoring_config["direction"]
      current_best = @game.scores.where(play_session: session).maximum(:value) if direction == "high"
      current_best = @game.scores.where(play_session: session).minimum(:value) if direction == "low"

      if current_best
        worse = direction == "high" ? params[:value].to_i <= current_best : params[:value].to_i >= current_best
        if worse
          render json: { ok: true, ignored: "not an improvement" }
          return
        end
      end
    end

    score = Score.new(
      game:         @game,
      player:       current_player,
      play_session: session,
      value:        params[:value],
      meta:         (params[:meta] || {}).to_unsafe_h.slice(*allowed_meta_keys)
    )

    if score.save
      render json: {
        ok: true,
        rank: rank_for(score),
        leaderboard: Score.leaderboard_for(@game, limit: 10).map { |s| score_row(s) }
      }
    else
      render json: { error: score.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.visible.friendly.find(params[:game_id])
  end

  # We accept free-form meta but only persist a known set of keys.
  # Games that need richer per-score context should extend this list
  # rather than splatting arbitrary params into the DB.
  def allowed_meta_keys
    %w[level time_ms seed distance combo difficulty]
  end

  def rank_for(score)
    direction = @game.scoring_config["direction"]
    op = direction == "high" ? ">" : "<"
    @game.scores.where("value #{op} ?", score.value).count + 1
  end

  def score_row(s)
    {
      player: s.player.name,
      value:  s.value,
      meta:   s.meta,
      at:     s.achieved_at.iso8601
    }
  end
end
