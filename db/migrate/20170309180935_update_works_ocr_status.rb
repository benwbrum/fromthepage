class UpdateWorksOcrStatus < ActiveRecord::Migration
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
      p.update_column(:status, "transcribed")
    end

  end
end
