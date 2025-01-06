module ResourcesHelper
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
end
