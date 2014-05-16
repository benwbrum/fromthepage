# handles administrative tasks for the work object
class WorkController < ApplicationController
  #  require 'ftools'

  protect_from_forgery :except => [:set_work_title,
                                   :set_work_description,
                                   :set_work_physical_description,
                                   :set_work_document_history,
                                   :set_work_permission_description,
                                   :set_work_location_of_composition,
                                   :set_work_author,
                                   :set_work_transcription_conventions]
  # tested
  before_filter :authorized?, :only => [:edit, :scribes_tab, :pages_tab, :delete, :new, :create]

  def authorized?
    unless user_signed_in? &&
      current_user.owner
      redirect_to dashboard_path
    else
      if @work && @work.owner != current_user
	redirect_to dashboard_path
      end
    end
  end

  def make_pdf
    # don't think there should be much to do here.
  end

  # TODO: refactor author to include docbook elements like fn, ln, on, hon, lin
  def create_pdf
    # render to string
    string = render_to_string :file => "#{Rails.root}/app/views/work/work.docbook"
#    # spew string to docbook tempfile

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
    redirect_to dashboard_path
  end

  def new
    @work = Work.new
  end

  def versions
    @page_versions = PageVersion.joins(:page).where(['pages.work_id = ?', @work.id]).order("work_version desc").all
  end

  def scribes_tab
    @scribes = @work.scribes
    @nonscribes = User.all - @scribes
  end

  def add_scribe
    @work.scribes << @user
    redirect_to :action => 'scribes_tab', :work_id => @work.id
  end

  def remove_scribe
    @work.scribes.delete(@user)
    redirect_to :action => 'scribes_tab', :work_id => @work.id
  end

  def update_work
    @work.update_attributes(params[:work])
    redirect_to :action => 'scribes_tab', :work_id => @work.id
  end

  # tested
  def create
    work = Work.new
    work.title = params[:work][:title]
    work.description = params[:work][:description]
    work.owner = current_user
    work.save!
    redirect_to dashboard_path
  end

  def update
    work = Work.find(params[:id])
    work.update_attributes(params[:work])
    flash[:notice] = "Work updated successfully."
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
end
