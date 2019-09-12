class SetDefaultOcrCorrectionValue < ActiveRecord::Migration
  def change
    # Set default value to false
    change_column :works, :ocr_correction, :boolean, default: false
    # Retroactively set NULL to false
    Work.where(ocr_correction: nil).update_all(ocr_correction: false)
  end
end
