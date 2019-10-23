class UpdateWorksOcrStatus < ActiveRecord::Migration[5.2]
  def change
    #find the work ids of current ocr correction works, then set those works as ocr correction works
    work_ids = Page.where("status = ? OR status = ?", 'raw_ocr', 'part_ocr').distinct.pluck(:work_id)
    works = Work.where(id: work_ids)
    works.each do |w|
      w.ocr_correction = true
      w.save!
    end

    #set pages that have a "part_ocr" status to "transcribed" status, without triggering callbacks
    pages = Page.where(status: 'part_ocr')
    pages.each do |p|
      p.update_columns(status: "transcribed")
    end
    #set pages with "raw_ocr" status to nil because we aren't using it anymore
    raw_pages = Page.where(status: 'raw_ocr')
    raw_pages.each do |p|
      p.update_columns(status: nil)
    end
  end
end
