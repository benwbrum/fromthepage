# handles administrative tasks for the work object
class WorkController < ApplicationController
  # require 'ftools'
  include XmlSourceProcessor

  protect_from_forgery :except => [:set_work_title,
                                   :set_work_description,
                                   :set_work_physical_description,
                                   :set_work_document_history,
                                   :set_work_permission_description,
                                   :set_work_location_of_composition,
                                   :set_work_author,
                                   :set_work_transcription_conventions]
  # tested
  before_filter :authorized?, :only => [:edit, :pages_tab, :delete, :new, :create]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    if !user_signed_in? || !current_user.owner
      ajax_redirect_to dashboard_path
    elsif @work && !current_user.like_owner?(@work)
      ajax_redirect_to dashboard_path
    end
  end

  def make_pdf
    # don't think there should be much to do here.
  end

  # TODO: refactor author to include docbook elements like fn, ln, on, hon, lin
  def create_pdf
    # render to string
    string = render_to_string :file => "#{Rails.root}/app/views/work/work.docbook"
    # spew string to docbook tempfile

    File.open(doc_tmp_path, "w") { |f| f.write(string) }
    if $?
      render(:text => "file write failed")
      return
    end

    dp_cmd = "#{DOCBOOK_2_PDF} #{doc_tmp_path} -o #{tmp_path}  -V bop-footnotes=t -V tex-backend > #{tmp_path}/d2p.out 2> #{tmp_path}/d2p.err"
    logger.debug("DEBUG #{dp_cmd}")
    #IO.popen(dp_cmd)

    if !system(dp_cmd)
      render_docbook_error
      return
    end

    if !File.exists?(pdf_tmp_path)
      render(:text => "#{dp_cmd} did not generate #{pdf_tmp_path}")
      return
    end

    if !File.copy(pdf_tmp_path, pdf_pub_path)
      render(:text => "could not copy pdf file to public/docs")
      return
    end
    @pdf_file = pdf_pub_path
  end

  def delete
    @work.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @work = Work.new
    @collections = current_user.all_owner_collections
  end

  def versions
    @page_versions = PageVersion.joins(:page).where(['pages.work_id = ?', @work.id]).order('page_versions.created_on DESC').paginate(page: params[:page], per_page: 20)
  end

  def edit
    @scribes = @work.scribes
    @nonscribes = User.all - @scribes
    @collections = current_user.collections
    #set subjects to true if there are any articles/page_article_links
    @subjects = !@work.articles.blank?
  end

  def add_scribe
    @work.scribes << @user
    redirect_to :action => 'edit', :work_id => @work
  end

  def remove_scribe
    @work.scribes.delete(@user)
    redirect_to :action => 'edit', :work_id => @work
  end

  def update_work
    @work.update_attributes(params[:work])
    redirect_to :action => 'edit', :work_id => @work
  end

  # tested
  def create
    @work = Work.new
    @work.title = params[:work][:title]
    @work.collection_id = params[:work][:collection_id]
    @work.description = params[:work][:description]
    @work.owner = current_user
    @collections = current_user.all_owner_collections

    if @work.save
      record_deed(@work)
      flash[:notice] = 'Work created successfully'
      ajax_redirect_to({ :controller => 'work', :action => 'pages_tab', :work_id => @work.id, :anchor => 'create-page' })
    else
      render :new
    end
  end

  def update
    work = Work.find(params[:id]) || Work.find_by(id: params[:work_id])
    id = work.collection_id
    #check the work transcription convention against the collection version
    #if they're the same, don't update that attribute of the work
    params_convention = params[:work][:transcription_conventions]
    collection_convention = work.collection.transcription_conventions

    if params_convention == collection_convention
      work.update_attributes(params[:work].except(:transcription_conventions))
    else
      work.update_attributes(params[:work])
    end

    #if the slug field param is blank, set slug to original candidate
    if params[:work][:slug] == ""
      title = work.title.parameterize
      work.update(slug: title)
    end

    if params[:work][:collection_id] != id.to_s
      change_collection
      flash[:notice] = 'Work updated successfully'
      #find new collection to properly redirect
      col = Collection.find_by(id: work.collection_id)
      redirect_to edit_collection_work_path(col.owner, col, work)
    else
      flash[:notice] = 'Work updated successfully'
      redirect_to :back
    end
  end

  def change_collection
    work = Work.find_by(id: params[:id])

    record_deed(work)
    unless work.articles.blank?
      #delete page_article_links for this work
      page_ids = work.pages.ids
      links = PageArticleLink.where(page_id: page_ids)
      links.destroy_all

      #remove links from pages in this work
      work.pages.each do |p|
        unless p.source_text.nil?
          p.remove_transcription_links(p.source_text)
        end
        unless p.source_translation.nil?
          p.remove_translation_links(p.source_translation)
        end
      end
      work.save!
    end
  end

  def revert
    work = Work.find_by(id: params[:work_id])
    work.update_attribute(:transcription_conventions, nil)
    render :text => work.collection.transcription_conventions
  end

  def update_featured_page
    @work.update(featured_page: params[:page_id])
    redirect_to :back
  end

  private
  def print_fn_stub
    @stub ||= DateTime.now.strftime("w#{@work.id}v#{@work.transcription_version}d%Y%m%dt%H%M%S")
  end

  def doc_fn
    "#{print_fn_stub}.docbook"
  end

  def pdf_fn
    "#{print_fn_stub}.pdf"
  end

  def tmp_path
    "#{Rails.root}/tmp"
  end

  def pub_path
    "#{Rails.root}/public/docs"
  end

  def pdf_tmp_path
    "#{tmp_path}/#{pdf_fn}"
  end

  def pdf_pub_path
    "#{pub_path}/#{pdf_fn}"
  end

  def doc_tmp_path
    "#{tmp_path}/#{doc_fn}"
  end

  def render_docbook_error
    msg = "docbook2pdf failure: <br /><br /> " +
      "stdout:<br />"
    File.new("#{tmp_path}/d2p.out").each { |l| msg+= l + "<br />"}
    msg += "<br />stderr:<br />"
    File.new("#{tmp_path}/d2p.err").each { |l| msg+= l + "<br />"}
    render(:text => msg )
  end

  protected
  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = Deed::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end
end