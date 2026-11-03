class Transcribe::Lib::DraftRecovery
  LIFETIME = 30.minutes

  def self.form_token(user:, page:, collection:, mode:)
    verifier.generate(
      { 'user_id' => user.id, 'page_id' => page.id, 'collection_id' => collection.id,
        'collection_type' => collection.class.name, 'owner_slug' => collection.owner.slug,
        'collection_slug' => collection.slug, 'work_slug' => page.work.slug, 'mode' => mode },
      purpose: 'form', expires_in: 1.day
    )
  end

  def self.verify_form(token, page_id:, mode:)
    return unless token.is_a?(String)

    context = verifier.verified(token, purpose: 'form')
    return unless context.is_a?(Hash) && context['page_id'].to_s == page_id.to_s && context['mode'] == mode

    context
  end

  def self.store(draft)
    id = SecureRandom.hex(32)
    id if Rails.cache.write(cache_key(id), draft, expires_in: LIFETIME)
  rescue StandardError => e
    Rails.logger.warn("Draft recovery cache write failed: #{e.class}")
    nil
  end

  def self.fetch(id)
    return unless valid_id?(id)

    Rails.cache.read(cache_key(id))
  rescue StandardError => e
    Rails.logger.warn("Draft recovery cache read failed: #{e.class}")
    nil
  end

  def self.delete(id)
    Rails.cache.delete(cache_key(id)) if valid_id?(id)
  rescue StandardError => e
    Rails.logger.warn("Draft recovery cache delete failed: #{e.class}")
  end

  def self.valid_id?(id)
    id.is_a?(String) && id.match?(/\A[0-9a-f]{64}\z/)
  end

  def self.cache_key(id)
    "transcription-draft-recovery:#{id}"
  end

  def self.verifier
    Rails.application.message_verifier('transcription-draft-recovery')
  end
end
