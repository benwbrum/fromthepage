class SessionsController < Devise::SessionsController
  def create
    super do |user|
      if user.cookies_consent_pending?
        consent_cache = cookies[:cookies_consent]&.to_sym || :pending

        return if consent_cache == :pending

        user.update!(cookies_consent: consent_cache)
      end
    end
  end
end
