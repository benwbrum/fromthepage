module ResourcesHelper
  def text_languages_collection
    ISO_639::ISO_639_2.map { |lang| [lang[3], lang[0]] }
  end

  def default_orientations_collection
    [
      [t('collection.edit_look.page_on_the_left'), 'ltr'],
      [t('collection.edit_look.page_on_the_right'), 'rtl'],
      [t('collection.edit_look.page_on_the_top'), 'ttb'],
      [t('collection.edit_look.page_on_the_bottom'), 'btt']
    ]
  end

  def default_overview_orientations_collection
    [
      [t('collection.edit_look.page_on_the_left'), 'ltr'],
      [t('collection.edit_look.page_on_the_top'), 'ttb']
    ]
  end

  def flash_icons
    {
      notice: '#icon-check-sign',
      alert: '#icon-warning-sign',
      error: '#icon-remove-sign',
      info: '#icon-warning-sign'
    }
  end

  def flash_aria_attributes(type)
    case type.to_sym
    when :notice, :info
      {
        role: 'status',
        'aria-live': 'polite',
        'aria-atomic': 'true'
      }
    when :alert, :error
      {
        role: 'alert',
        'aria-live': 'assertive',
        'aria-atomic': 'true'
      }
    else
      {
        role: 'status',
        'aria-live': 'polite',
        'aria-atomic': 'true'
      }
    end
  end

  def categories_options(categories)
    options = []
    categories.walk_tree do |c, level|
      options << [
        c.title,
        c.id,
        {
          aria: { label: I18n.t('category.options') },
          data: { level: level }
        }
      ]
    end

    options
  end

  def collections_and_document_sets_options
    scope = current_user.collections.includes(:document_sets)

    options = []

    scope.sort_by(&:title).each do |collection|
      options << [
        collection.title,
        collection.slug,
        { data: { level: 0 } }
      ]

      collection.document_sets.sort_by(&:title).each do |doc_set|
        options << [
          doc_set.title,
          doc_set.slug,
          { data: { level: 1 } }
        ]
      end
    end

    options << [
      t('dashboard.empty.add_new_collection'),
      'new',
      { data: { litebox: { url: collection_new_path, hash: 'create-collection' } } }
    ]

    options
  end

  def works_list_show_options
    [
      [t('collection.collection_works.all_works'), 'all'],
      [t('collection.collection_works.works_that_need_transcription'), 'need_transcription']
    ]
  end

  def document_set_inclusion_options
    [
      [t('document_sets.edit_works.all_works'), 'all'],
      [t('document_sets.edit_works.included'), 'included'],
      [t('document_sets.edit_works.not_included'), 'not_included']
    ]
  end

  def document_set_visibility_options
    DocumentSet.visibilities.keys.map do |key|
      [t("document_sets.new.#{key}"), key]
    end
  end

  def suspicious_behavior_type_options
    SuspiciousBehavior::BEHAVIOR_TYPE_FILTERS.map do |key|
      [t("suspicious_behaviors.filters.behavior_type.#{key}"), key]
    end
  end

  def suspicious_behavior_status_options
    SuspiciousBehavior::STATUS_FILTERS.map do |key|
      [t("suspicious_behaviors.filters.status.#{key}"), key]
    end
  end

  def suspicious_behavior_action_options
    SuspiciousBehavior::ACTION_FILTERS.map do |key|
      [t("suspicious_behaviors.filters.action.#{key}"), key]
    end
  end
end
