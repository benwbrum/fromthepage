module Components::FiltersHelper
  def fe_filter_table_wrapper(selector:, &block)
    selector = "#{selector}-wrapper"
    classes = 'dataTables_wrapper'

    render('shared/components/filter_table_wrapper', selector: selector, classes: classes) do
      capture(&block)
    end
  end

  def fe_filter_form_wrapper(url:, selector:, sorting:, ordering:, static_params: {}, &block)
    selector = "#{selector}-form"

    dataset = {
      filter_table_target: 'form',
      turbo: true
    }

    render('shared/components/filter_table_form_wrapper',
           url: url, selector: selector, dataset: dataset, sorting: sorting, ordering: ordering,
           static_params: static_params) do
      capture(&block)
    end
  end

  def fe_filter_table(selector:, &block)
    render('shared/components/filter_table', selector: selector) do
      capture(&block)
    end
  end

  def fe_filter_page_size_select(page_options: pagination_options_collection, selected: nil)
    render('shared/components/page_size_select', page_options: page_options, selected: selected)
  end

  def fe_filter_search(key:, value: nil, classes: nil, placeholder: nil, wrapper_class: 'dataTables_filter search',
                       with_button: false)
    classes = "#{wrapper_class} #{classes}"

    render('shared/components/filter_search', key: key, value: value, classes: classes, placeholder: placeholder,
                                              with_button: with_button)
  end

  def fe_filter_select(key:, value: nil, options: [], classes: nil)
    classes = "dataTables_filter #{classes}"

    render('shared/components/filter_select', key: key, value: value, options: options, classes: classes)
  end

  def fe_filter_select(key:, value: nil, options: [], classes: nil)
    classes = "dataTables_filter #{classes}"

    render('shared/components/filter_select', key: key, value: value, options: options, classes: classes)
  end

  def fe_sortable_header(key:, sorting:, ordering:, classes: nil, &block)
    sorting_class = "sorting_#{ordering}"

    classes = "sorting #{classes}"
    classes = "#{classes} #{key.to_s == sorting.to_s ? sorting_class : ''}"

    render('shared/components/sortable_header', key: key, classes: classes) do
      capture(&block)
    end
  end

  def fe_table_no_contents
    render('shared/components/table_no_contents')
  end

end
