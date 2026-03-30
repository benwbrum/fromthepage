# :nocov:
module PageCaching
  extend ActiveSupport::Concern

  included do
    etag { current_user&.id }
    etag { current_user&.updated_at }
    etag { request.accept }
    etag { request.params.to_json }

    before_action :prepare_custom_etags
  end

  def prepare_custom_etags
    @custom_etags ||= []
  end

  def add_etags(*etags)
    @custom_etags.concat(etags)
  end

  def cache_fresh?(etags: [])
    raise 'Only GET/HEAD requests are supported' unless request.get? || request.head?

    etags = etags.map { |etag| etag&.cache_key_with_version }.compact
    add_etags(etags) if etags.any?

    !stale?(etag: cache_key)
  end

  private

  def cache_key
    @cache_key ||= ([etag_values, @custom_etags].flatten.compact.join('-'))
  end

  def etag_values
    self.class.etaggers.map { |block| instance_exec(&block) }
  end

  module ClassMethods
    def etag(&block)
      etaggers << block
    end

    def etaggers
      @etaggers ||= []
    end
  end
end
# :nocov:
