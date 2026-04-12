class Arcade::DashboardController < Arcade::BaseController
  def index
    @games = current_player.games.visible.order(created_at: :desc)

    # Aggregate stats per game — one query each, scoped to the owner's games.
    # For 10s of games this is fine; if it grows we can push into SQL with a
    # lateral join or denormalize onto `games`.
    @stats = @games.each_with_object({}) do |game, h|
      sessions = game.play_sessions
      h[game.id] = {
        plays:           sessions.count,
        unique_players:  sessions.distinct.count(:player_id),
        total_time_ms:   sessions.where.not(duration_ms: nil).sum(:duration_ms),
        completed:       sessions.where(completed: true).count,
        top_scores:      Score.leaderboard_for(game, limit: 5)
      }
    end
  end
end
