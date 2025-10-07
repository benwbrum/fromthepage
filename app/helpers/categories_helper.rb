module CategoriesHelper
  def category_tree_accordion(tree, show_uncategorized:, selected_id: nil, expanded: false, recurse_step: false)
    content_tag(:ul, data: recurse_step ? {} : { controller: 'toggle-view' }) do
      items = tree.map do |node|
        category = node[:category]
        children = node[:children]

        content_tag(:li,
          class: expanded ? 'expanded' : nil,
          data: {
            toggle_view_target: 'toggleable',
            toggle_class: 'expanded',
            toggle_self: true,
            action: 'click->toggle-view#toggle'
          }
        ) do
          link = content_tag(:a,
            class: "tree-item #{'selected' if category.id == selected_id}",
            data: {
              filter_table_target: 'listButton',
              list: 'selected_category_id',
              value: category.id
            }
          ) do
            safe_join([
              (content_tag(:span, '', class: 'tree-bullet') if children.any?),
              content_tag(:span, category.title)
            ].compact)
          end

          subtree = if children.any?
            category_tree_accordion(children, show_uncategorized: show_uncategorized, selected_id: selected_id, expanded: expanded, recurse_step: true)
          else
            ''.html_safe
          end

          safe_join([link, subtree])
        end
      end

      if !recurse_step && show_uncategorized
        uncategorized_item = content_tag(:li) do
          content_tag(:a,
            t('article.list.uncategorized'),
            class: "tree-item #{'selected' if selected_id == 'uncategorized'}",
            data: {
              filter_table_target: 'listButton',
              list: 'selected_category_id',
              value: 'uncategorized'
            }
          )
        end

        items << uncategorized_item
      end

      safe_join(items)
    end
  end
end
