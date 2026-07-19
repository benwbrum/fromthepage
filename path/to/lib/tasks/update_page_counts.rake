# frozen_string_literal: true

namespace :update_page_counts do
  desc 'Update page counts for all pages'
  task update: :environment do
    Page.all.each do |page|
      PageCountCalculator.new.update_page_count(page, false)
    end
  end
end