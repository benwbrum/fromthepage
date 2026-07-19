# frozen_string_literal: true

class PageCountCalculator
  def calculate_page_count(pages)
    active_pages = pages.select(&:active?)
    inactive_pages = pages.select { |page| !page.active? }

    active_pages.size + inactive_pages.size
  end

  def update_page_count(page, new_status)
    if new_status
      page.update(page_count: page.page_count - 1)
    else
      page.update(page_count: page.page_count + 1)
    end
  end
end