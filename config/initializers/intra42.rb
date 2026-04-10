# 42 intra OAuth2 configuration.
#
# The app boots fine whether or not these are set. In development, leave
# them blank — the arcade will just not offer the "sign in with 42" option.
# In production, set:
#
#   INTRA_UID        = 42 application UID
#   INTRA_SECRET     = 42 application secret
#   INTRA_REDIRECT   = https://yourhost/arcade/auth/intra/callback  (optional,
#                      defaults to the configured callback route)
#
module Intra42
  AUTHORIZE_URL = "https://api.intra.42.fr/oauth/authorize".freeze
  TOKEN_URL     = "https://api.intra.42.fr/oauth/token".freeze
  USER_URL      = "https://api.intra.42.fr/v2/me".freeze
  SCOPE         = "public".freeze

  module_function

  def configured?
    ENV["INTRA_UID"].present? && ENV["INTRA_SECRET"].present?
  end

  def client
    return nil unless configured?

    OAuth2::Client.new(
      ENV["INTRA_UID"],
      ENV["INTRA_SECRET"],
      site:          "https://api.intra.42.fr",
      authorize_url: "/oauth/authorize",
      token_url:     "/oauth/token"
    )
  end
end
