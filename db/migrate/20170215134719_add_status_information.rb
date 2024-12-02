class AddStatusInformation < ActiveRecord::Migration[5.0]
  def change
    #add needs review to work statistics
    add_column :work_statistics, :needs_review, :integer

    #add translation status to pages
    unless column_exists?(:pages, :translation_status)
      add_column :pages, :translation_status, :string
    end

    #add translation columns to work statistics
    add_column :work_statistics, :translated_pages, :integer
    add_column :work_statistics, :translated_blank, :integer
    add_column :work_statistics, :translated_review, :integer
    add_column :work_statistics, :translated_annotated, :integer

    #add ocr correction flag to work
    add_column :works, :ocr_correction, :boolean
  end

end
