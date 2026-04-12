class Arcade::SessionsController < Arcade::BaseController
  # Hand-rolled 42 intra OAuth2 flow. Three actions:
  #
  #   new      → redirect to 42 authorize URL
  #   callback → exchange the code, look up / create Identity, claim the
  #              current anon player if the provider has never been linked
  #              before (so the anon's scores/games follow them in)
  #   destroy  → forget the current player (next request re-mints an anon)
  #
  # This whole flow is a no-op unless Intra42.configured? is true, so the
  # app boots fine without INTRA_UID / INTRA_SECRET in dev.

  def new
    unless Intra42.configured?
      redirect_to arcade_root_path, alert: "42 sign-in is not configured on this server."
      return
    end

    state = SecureRandom.urlsafe_base64(32)
    session[:intra_oauth_state] = state

    url = Intra42.client.auth_code.authorize_url(
      redirect_uri: callback_url,
      scope:        Intra42::SCOPE,
      state:        state
    )

    redirect_to url, allow_other_host: true
  end

  def callback
    unless Intra42.configured?
      redirect_to arcade_root_path, alert: "42 sign-in is not configured." and return
    end

    if params[:state].blank? || params[:state] != session.delete(:intra_oauth_state)
      redirect_to arcade_root_path, alert: "Sign-in failed (state mismatch). Please try again." and return
    end

    if params[:error].present?
      redirect_to arcade_root_path, alert: "42 sign-in cancelled." and return
    end

    token = Intra42.client.auth_code.get_token(params[:code], redirect_uri: callback_url)
    info  = token.get(Intra42::USER_URL).parsed

    player = link_or_claim_player(info)
    sign_in_player!(player)

    redirect_to arcade_dashboard_path, notice: "Welcome, #{player.name}."
  rescue OAuth2::Error => e
    Rails.logger.warn("[arcade intra] oauth error: #{e.message}")
    redirect_to arcade_root_path, alert: "42 sign-in failed. Please try again."
  end

  def destroy
    cookies.delete(:arcade_player_token)
    redirect_to arcade_root_path, notice: "Signed out."
  end

  private

  def callback_url
    ENV["INTRA_REDIRECT"].presence || arcade_auth_intra_callback_url
  end

  # Core claim logic:
  #
  # 1. If an Identity already exists for this (intra42, uid) → that's the
  #    returning player. Sign them in. If the current browser still holds
  #    a DIFFERENT anon player, leave that anon alone (future slice: offer
  #    a manual merge UI with audit trail).
  #
  # 2. If no Identity exists → attach one to whatever player the browser
  #    is currently acting as. This is the "claim" path: an anonymous
  #    player keeps all their games/scores and just gains an intra login.
  def link_or_claim_player(info)
    uid   = info["id"].to_s
    login = info["login"]
    email = info["email"]

    identity = Identity.find_by(provider: Identity::PROVIDER_INTRA42, uid: uid)

    if identity
      player = identity.player
      identity.update(raw_info: info)
    else
      player = current_player || Player.create!(anon_token: SecureRandom.hex(32))
      player.identities.create!(
        provider: Identity::PROVIDER_INTRA42,
        uid:      uid,
        raw_info: info
      )
    end

    player.update!(
      intra_login:  login,
      email:        email,
      display_name: info["displayname"].presence || login
    )

    player
  end

  def sign_in_player!(player)
    # Re-use the same signed-cookie mechanism as anonymous players. We
    # don't issue a separate session cookie because there's no password
    # and the anon_token is effectively a long-lived bearer handle.
    cookies.signed.permanent[:arcade_player_token] = {
      value:     player.anon_token,
      httponly:  true,
      same_site: :lax
    }
    @current_player = player
  end
end
