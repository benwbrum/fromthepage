class AddStatusInformation < ActiveRecord::Migration
  def change
    #add needs review to transcribe and translate work statistics
    add_column :work_statistics, :needs_review, :integer

    #add ocr correction flag to work
    add_column :works, :ocr_correction, :boolean
  end

end
