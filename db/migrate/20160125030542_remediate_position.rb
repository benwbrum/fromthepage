class RemediatePosition < ActiveRecord::Migration[5.0]

  def change
    Work.all.each do |work|
      next unless !work.pages.empty? &&
                  work.pages.first.base_image.include?('uploaded') &&
                  work.pages.first.id != work.pages.sort do |x, y|
                                           x.base_image <=> y.base_image
                                         end.first.id

      print "Reordering work id=#{work.id}, title=#{work.title}\n"
      work.pages.sort do |x, y|
        x.base_image <=> y.base_image
      end.each_with_index { |page, i| page.update_columns(position: i, title: i.to_s) }
    end
  end

end
