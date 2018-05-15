require 'contentdm_translator'
class ExportController < ApplicationController
  require 'zip'
  include CollectionHelper

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil } #, :only => [:update, :update_profile]

  def index
    @collection = Collection.friendly.find(params[:collection_id])
    #check if there are any translated works in the collection
    if @collection.works.where(supports_translation: true).exists?
      @header = "Translated"
    else
      @header = "Transcribed"
    end

    @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 15)

    @table_export = @collection.works.joins(:table_cells).where.not(table_cells: {work_id: nil}).distinct
  end

  def show
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def tei
    params[:format] = 'xml'# if params[:format].blank?

    @context = ExportContext.new

    @user_contributions =
      User.find_by_sql("SELECT  user_id user_id,
                                users.print_name print_name,
                                count(*) edit_count,
                                min(page_versions.created_on) first_edit,
                                max(page_versions.created_on) last_edit
                        FROM    page_versions
                        INNER JOIN pages
                            ON page_versions.page_id = pages.id
                        INNER JOIN users
                            ON page_versions.user_id = users.id
                        WHERE pages.work_id = #{@work.id}
                          AND page_versions.transcription IS NOT NULL
                        GROUP BY user_id
                        ORDER BY count(*) DESC")

    @work_versions = PageVersion.joins(:page).where(['pages.work_id = ?', @work.id]).order("work_version DESC").includes(:page).all

    @all_articles = @work.articles

    @person_articles = @all_articles.joins(:categories).where(categories: {title: 'People'})
    @place_articles = @all_articles.joins(:categories).where(categories: {title: 'Places'})
    @other_articles = @all_articles.joins(:categories).where.not(categories: {title: 'People'})
                      .where.not(categories: {title: 'Places'})
    render :layout => false, :content_type => "application/xml", :template => "export/tei.html.erb"
  end

  def subject_csv
    send_data(@collection.export_subjects_as_csv,
              :filename => "fromthepage_subjects_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    # cookies['download_finished'] = 'true'
  end
  
  def table_csv
    send_data(export_tables_as_csv(@work),
              :filename => "fromthepage_tables_export_#{@work.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
    
  end

  def export_all_works
    unless @collection.subjects_disabled
      @works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: @collection.id)
    else
      @works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: @collection.id)
    end      

#create a zip file which is automatically downloaded to the user's machine
    respond_to do |format|
      format.html
      format.zip do
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        @works.each do |work|
          @work = work
          export_view = render_to_string(:action => 'show', :formats => [:html], :work_id => work.id, :layout => false, :encoding => 'utf-8')
          zos.put_next_entry "#{work.slug.truncate(200, omission: "")}.xhtml"
          zos.print export_view
        end
      end
      compressed_filestream.rewind
      send_data compressed_filestream.read, filename: "#{@collection.title}.zip"
      end
    end
    cookies['download_finished'] = 'true'
  end

  def export_all_tables
    send_data(export_tables_as_csv(@collection),
              :filename => "fromthepage_tables_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
   
  end

  def page_plaintext_verbatim
    render  :layout => false, :content_type => "text/plain", :text => @page.verbatim_transcription_plaintext
  end

  def page_plaintext_translation_verbatim
    render  :layout => false, :content_type => "text/plain", :text => @page.verbatim_translation_plaintext
  end

  def page_plaintext_emended
    render  :layout => false, :content_type => "text/plain", :text => @page.emended_transcription_plaintext
  end

  def page_plaintext_translation_emended
    render  :layout => false, :content_type => "text/plain", :text => @page.emended_translation_plaintext
  end

  def page_plaintext_searchable
    render  :layout => false, :content_type => "text/plain", :text => @page.search_text
  end

  def work_plaintext_verbatim
    render  :layout => false, :content_type => "text/plain", :text => @work.verbatim_transcription_plaintext
  end

  def work_plaintext_translation_verbatim
    render  :layout => false, :content_type => "text/plain", :text => @work.verbatim_translation_plaintext
  end

  def work_plaintext_emended
    render  :layout => false, :content_type => "text/plain", :text => @work.emended_transcription_plaintext
  end

  def work_plaintext_translation_emended
    render  :layout => false, :content_type => "text/plain", :text => @work.emended_translation_plaintext
  end

  def work_plaintext_searchable
    render  :layout => false, :content_type => "text/plain", :text => @work.searchable_plaintext
  end
  
  
  def edit_contentdm_credentials
    # display the edit form
  end
  
  def update_contentdm_credentials
    # test credentials
    license_key = params[:collection][:license_key]
    contentdm_user_name = params[:contentdm_user_name]
    contentdm_password = params[:contentdm_password]
    
    error_message, fts_field = ContentdmTranslator.fst_field_for_collection(@collection, license_key, contentdm_user_name, contentdm_password)

    # persist license key so the user doesn't have to retype it    
    if error_message.blank? || !error_message.match(/license.*invalid/)
      @collection.license_key = license_key
      @collection.save!
    end
    
    # redirect to or render edit screen with error
    if error_message
      flash[:error] = error_message
      render :action => :edit_contentdm_credentials, :collection_id => @collection.id
      return
    end

    # pass credentials, FTS field, and search to background job
    log_file = ContentdmTranslator.log_file(@collection)
    cmd = "rake fromthepage:cdm_transcript_export[#{@collection.id}] > #{log_file} 2>&1 &"
    logger.info(cmd)
    system({'contentdm_username' => contentdm_user_name, 'contentdm_password' => contentdm_password, 'contentdm_license' => license_key}, cmd)

    # display results somehow
    flash[:notice] = "Updating CONTENTdm.  You should receive an email when the sync completes, then will need to rebuild your index for the changes to appear."
    ajax_redirect_to :action => :index, :collection_id => @collection.id
  end
private

  def get_headings(collection, ids)
    field_headings = collection.transcription_fields.order(:position).pluck(:label)
    cell_headings = TableCell.where(work_id: ids).pluck('DISTINCT header')
    @raw_headings = (field_headings + cell_headings).uniq
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    #get headings from field-based
    field_headings.each do |raw_heading|
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    #get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    @headings.uniq!
  end

  def export_tables_as_csv(table_obj)
    if table_obj.is_a?(Collection)
      collection = table_obj
      ids = table_obj.works.ids
      works = table_obj.works
    elsif table_obj.is_a?(Work)
      collection = table_obj.collection
      #need arrays so they will act equivalently to the collection works
      ids = [table_obj.id]
      works = [table_obj]
    end

    get_headings(collection, ids)

    csv_string = CSV.generate(:force_quotes => true) do |csv|
      if table_obj.sections.blank?
        csv << (['Work Title', 'Work Identifier', 'Page Title', 'Page Position', 'Page URL' ] + @headings)
        col_sections = false
      else
        csv << (['Work Title', 'Work Identifier', 'Page Title', 'Page Position', 'Page URL', 'Section (text)', 'Section (subjects)', 'Section (subject categories)' ] + @headings)
        col_sections = true
      end
      works.each do |w|
        csv = generate_csv(w, csv, col_sections)
      end
    end
    cookies['download_finished'] = 'true'
    csv_string
  end

  def generate_csv(work, csv, col_sections)
    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        page_url=url_for({:controller=>'display',:action => 'display_page', :page_id => page.id, :only_path => false})
        page_cells = [work.title, work.identifier, page.title, page.position, page_url]
        page_metadata_cells = page_metadata_cells(page)
        data_cells = Array.new(@headings.count, "")

        if page.sections.blank?
          #get cell data for a page with only one table
          page.table_cells.group_by(&:row).each do |row, cell_array|
            #get the cell data and add it to the array
            cell_data(cell_array, @raw_headings, data_cells)
            #shift cells over if any page has sections
            if !col_sections
              section_cells = []
            else
              section_cells = ["", "", ""]
            end
            # write the record to the CSV and start a new record
            csv << (page_cells + page_metadata_cells + section_cells + data_cells)
            #create a new array for the next row
            data_cells = Array.new(@headings.count, "")
          end

        else
          #get the table sections/headers and iterate cells within the sections
          page.sections.each do |section|
            section_title_text = XmlSourceProcessor::cell_to_plaintext(section.title) || nil
            section_title_subjects = XmlSourceProcessor::cell_to_subject(section.title) || nil
            section_title_categories = XmlSourceProcessor::cell_to_category(section.title) || nil
            section_cells = [section_title_text, section_title_subjects, section_title_categories]
            #group the table cells per section into rows
            section.table_cells.group_by(&:row).each do |row, cell_array|
              #get the cell data and add it to the array
              cell_data(cell_array, @raw_headings, data_cells)
              # write the record to the CSV and start a new record
              csv << (page_cells + page_metadata_cells + section_cells + data_cells)
              #create a new array for the next row
              data_cells = Array.new(@headings.count, "")
            end
          end
        end
      end
    end
    return csv
  end

  def page_metadata_cells(page)
    metadata_cells = []
    @page_metadata_headings.each do |key|
      metadata_cells << page.metadata[key]
    end
    
    metadata_cells
  end

  def cell_data(array, raw_headings, data_cells)
    array.each do |cell|
      target = (raw_headings.index(cell.header))*2
      data_cells[target] = XmlSourceProcessor.cell_to_plaintext(cell.content)
      data_cells[target+1] = XmlSourceProcessor.cell_to_subject(cell.content)
    end
  end


end