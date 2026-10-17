class Deed::Calculate < ApplicationInteractor
  attr_accessor :deed

  def initialize(deed:)
    @deed = deed

    super
  end

  def perform
    handle_prerender
    handle_prerender_mailer
    handle_collections_most_recent_deed
    handle_works_most_recent_deed
  end

  private

  def locales
    # Don't include regional locales
    @locales ||= I18n.available_locales.reject { |locale| locale.to_s.include? '-' }
  end

  # TODO: We are migrating away from caching prerenders into caching via solid_queue
  def handle_prerender
    return if [DeedType::COLLECTION_INACTIVE, DeedType::COLLECTION_ACTIVE].include?(@deed.deed_type)

    renderer = ApplicationController.renderer.new

    prerender_json = locales.to_h do |locale|
      [
        locale,
        renderer.render(
          partial: 'deed/deed',
          locals: {
            deed: @deed,
            long_view: false,
            prerender: true,
            locale: locale
          },
          formats: [:html]
        )
      ]
    end.to_json

    @deed.update_columns(prerender: prerender_json)
  end

  # TODO: We are migrating away from caching prerenders into caching via solid_queue
  def handle_prerender_mailer
    renderer = ApplicationController.renderer.new

    prerender_mailer_json = locales.to_h do |locale|
      [
        locale,
        renderer.render(
          partial: 'deed/deed',
          locals: {
            deed: @deed,
            long_view: true,
            prerender: true,
            mailer: true,
            locale: locale
          },
          formats: [:html]
        )
      ]
    end.to_json

    @deed.update_columns(prerender_mailer: prerender_mailer_json)
  end

  def handle_collections_most_recent_deed
    return unless @deed.collection.present?

    @deed.collection.update_columns(most_recent_deed_created_at: @deed.created_at)
  end

  def handle_works_most_recent_deed
    return unless @deed.work.present?

    @deed.work.update_columns(most_recent_deed_created_at: @deed.created_at)
  end
end
