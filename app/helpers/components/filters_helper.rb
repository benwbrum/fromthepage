module Components::FiltersHelper

  def fe_filter_table_wrapper(url:, selector:, sorting:, ordering:, static_params: {}, &block)
    dataset = {
      filterable_table: true,
      filterable_table_selector: selector,
    }
    selector = "#{selector}-form"
    classes = 'dataTables_wrapper'

    render('shared/components/filter_table_wrapper',
           url: url, selector: selector, classes: classes,
           dataset: dataset, sorting: sorting, ordering: ordering, static_params: static_params) do
      capture(&block)
    end
  end

  def fe_filter_page_size_select(page_options: pagination_options_collection, selected: nil)
    render('shared/components/page_size_select', page_options: page_options, selected: selected)
  end

  def fe_filter_search(key:, value: nil, classes: nil)
    classes = "dataTables_filter search #{classes}"

    render('shared/components/filter_search', key: key, value: value, classes: classes)
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
