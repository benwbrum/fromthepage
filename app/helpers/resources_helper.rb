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

  def flash_icons
    {
      notice: '#icon-check-sign',
      alert: '#icon-warning-sign',
      error: '#icon-remove-sign',
      info: '#icon-warning-sign'
    }
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
end
