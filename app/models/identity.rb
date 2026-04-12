class Identity < ApplicationRecord
  # Links a Player to an external auth provider (42 intra, later maybe
  # github). The (provider, uid) tuple is unique — one provider account can
  # only point at one Player at a time.

  belongs_to :player

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }

  PROVIDER_INTRA42 = "intra42".freeze

  def self.find_or_initialize_from_auth(auth)
    find_or_initialize_by(provider: auth.provider.to_s, uid: auth.uid.to_s)
  end
end
