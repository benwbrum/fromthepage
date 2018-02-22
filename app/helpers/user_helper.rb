module UserHelper

  def user_activity(user)
    @user = user
    #collections the user has worked in
    col_ids = @user.deeds.pluck(:collection_id).uniq
    #works that have been added to those collections by someone other than the user in the past day
    @added_works = Work.where(collection_id: col_ids).joins(:deeds).where(deeds: {deed_type: 'work_add'}).merge(Deed.past_day).where.not(deeds: {user_id: @user.id}).distinct
    #find edited pages
    pages = Page.joins(:deeds).where(deeds: {deed_type: ['page_edit', 'ocr_corr', 'review']}).merge(Deed.past_day).distinct
    #find pages with notes
    note_pages = Page.joins(:deeds).where(deeds: {deed_type: 'note_add'}).merge(Deed.past_day).distinct

    #find which pages the user has worked on
    user_page_ids = user.deeds.where(deeds: {deed_type: ['page_trans', 'page_edit', 'review', 'note_add', 'ocr_corr']}).pluck(:page_id).uniq
    #find pages that have been newly edited by someone other than the user (the user is not the last editor)
    @active_pages = pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: ['page_trans', 'page_edit', 'review', 'ocr_corr']).last.user_id != user.id}
    #find pages that the user has worked on that has had notes added recently
    @active_note_pages = note_pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: 'note_add').last.user_id != user.id}
  end

end