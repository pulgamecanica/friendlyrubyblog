module ActorFingerprint
  extend ActiveSupport::Concern
  ACTOR_COOKIE_KEY = :anon_actor

  included { before_action :ensure_actor_cookie! }

  def current_actor_hash = cookies.signed[ACTOR_COOKIE_KEY]
  def ip_hash            = Digest::SHA256.hexdigest(request.remote_ip.to_s)
  def user_agent_hash    = Digest::SHA256.hexdigest(request.user_agent.to_s)

  private
  def ensure_actor_cookie!
    return if cookies.signed[ACTOR_COOKIE_KEY].present?
    cookies.permanent.signed[ACTOR_COOKIE_KEY] = {
      value: SecureRandom.hex(16),
      httponly: true,
      same_site: :lax
      # secure: true
    }
  end
end
