class RemediatePosition < ActiveRecord::Migration[5.2]
  def change
    Work.all.each do |work| 
      if !work.pages.empty? && work.pages.first.base_image.include?("uploaded") && work.pages.first.id != work.pages.sort{ |x,y| x.base_image <=> y.base_image }.first.id
        print "Reordering work id=#{work.id}, title=#{work.title}\n"
        work.pages.sort{|x,y| x.base_image <=> y.base_image}.each_with_index  { |page,i| page.update_columns(:position => i, :title => i.to_s)}
      end 
    end

  end
end
