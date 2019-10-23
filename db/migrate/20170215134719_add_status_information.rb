class AddStatusInformation < ActiveRecord::Migration[5.2]
  def change
    #add needs review to work statistics
    add_column :work_statistics, :needs_review, :integer

    #add translation status to pages
    add_column :pages, :translation_status, :string

    #add translation columns to work statistics
    add_column :work_statistics, :translated_pages, :integer
    add_column :work_statistics, :translated_blank, :integer
    add_column :work_statistics, :translated_review, :integer
    add_column :work_statistics, :translated_annotated, :integer

    #add ocr correction flag to work
    add_column :works, :ocr_correction, :boolean
  end

end
