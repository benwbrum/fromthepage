class UserMailerPreview < ActionMailer::Preview

  def upload_finished
    UserMailer.upload_finished(DocumentUpload.last)
  end

  def new_owner
    block = PageBlock.find_by(view: "new_owner").html
    user = User.find_by(login: 'admin')
    UserMailer.new_owner(user, block)
  end

  def added_note
    user = User.find_by(login: 'admin')
    note = Note.first
    UserMailer.added_note(user, note)
  end

  def collection_collaborator
    user = User.find_by(login: 'admin')
    collection = Collection.last
    UserMailer.collection_collaborator(user, collection)
  end

  def document_set_collaborator
    user = User.find_by(login: 'admin')
    set = DocumentSet.last
    UserMailer.collection_collaborator(user, set)
  end

  def work_collaborator
    user = User.find_by(login: 'admin')
    work = Work.last
    UserMailer.work_collaborator(user, work)
  end

  def added_work
    user = User.find_by(login: 'admin')
    work = Work.last(3).first
    UserMailer.added_work(user, work)
  end

  def page_edited
    user = User.find_by(login: 'admin')
    page = Page.last(5).first
    UserMailer.page_edited(user, page)
  end    

end
