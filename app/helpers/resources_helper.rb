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
end
