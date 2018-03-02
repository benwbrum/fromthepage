class DeedDTO
attr_accessor :collection, :deed, :work, :user,:created_at

  def initialize(deed)
    @collection = deed.collection.title  
    @deed = deed
    @work = deed.work.title
    @id = deed.id
    @deed_type = deed.deed_type
    @page = deed.page
    @user = deed.user.display_name
    @created_at = deed.created_at
    @updated_at = deed.updated_at

    case deed.deed_type
        when 'page_trans'
          @deed_type = "transcribed page "

        when 'page_edit'
          @deed_type = "edited page "

        when 'page_index'
          @deed_type = "indexed page "

        when 'art_edit'
          @deed_type = "edited #{article} article"

        when 'note_add'
          @deed_type = "added a note to page "

        when 'pg_xlat'
          @deed_type = "translated page "

        when 'pg_xlat_ed'
          @deed_type = "edited the translation of page "

        when 'ocr_corr'
          @deed_type = "corrected page "

        when 'review'
          @deed_type = "marked page  as needing review"

        when 'xlat_index'
          @deed_type = "indexed the translation of page "

        when 'xlat_rev'
          @deed_type = "marked translation page  as needing review"

        when 'work_add'
          @deed_type = "added #{work}"
        else
            @deed_type = "No action"
    end   
end  
end  