# frozen_string_literal: true

class Page < ApplicationRecord
  # ...

  def inactive
    update(page_count: page_count - 1)
  end

  def mark_inactive
    inactive
  end

  private

  def page_count
    # Assume this method is implemented elsewhere
  end
end