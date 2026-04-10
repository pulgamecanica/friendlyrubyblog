class GameIngestionJob < ApplicationJob
  # Runs the ingestion service in the background so a git clone + make
  # doesn't block the request thread.
  queue_as :default

  def perform(game_id)
    game = Game.find(game_id)
    GameIngestionService.call(game)
  end
end
