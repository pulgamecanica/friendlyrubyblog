class Arcade::PlayController < ApplicationController
  # Serves a game's build artifacts (html, js, wasm, css, data) from a
  # consistent URL path so relative references between them work:
  #
  #   /arcade/games/:slug/play/demo.html  → text/html
  #   /arcade/games/:slug/play/demo.js    → application/javascript
  #   /arcade/games/:slug/play/demo.wasm  → application/wasm
  #
  # The game's HTML loads demo.js which loads demo.wasm via a relative path.
  # Active Storage redirect URLs break this; this controller doesn't.
  #
  # No layout — these are raw files served with the correct Content-Type.
  # The game's HTML page runs in an iframe on the show page.

  skip_before_action :verify_authenticity_token

  def show
    game = Game.visible.friendly.find(params[:game_id])
    block = game.mlx42_block

    unless block
      head :not_found
      return
    end

    filename = params[:filename]

    # Find the artifact by filename among the block's game_artifacts.
    artifact = block.game_artifacts.find { |a| a.filename.to_s == filename }

    unless artifact
      head :not_found
      return
    end

    # Serve with correct Content-Type and aggressive caching (the blob
    # key changes when the game is resubmitted, so stale caches aren't
    # a concern).
    response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"
    response.headers["Cross-Origin-Opener-Policy"] = "same-origin"

    send_data artifact.download,
              filename:    filename,
              type:        artifact.content_type,
              disposition: :inline
  end
end
