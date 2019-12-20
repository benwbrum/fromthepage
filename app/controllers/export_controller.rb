require 'contentdm_translator'
class ExportController < ApplicationController
  require 'zip'
  include CollectionHelper,ExportHelper

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil } #, :only => [:update, :update_profile]

  README = []

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

  def text
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def transcript
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def translation
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
    
    ### Catch the rendered Work for post-processing
    xml = render_to_string :layout => false, :template => "export/tei.html.erb"

    # Render the post-processed
    render :text => post_process_xml(xml, @work), :content_type => "application/xml"
  end

  def subject_csv
    send_data(@collection.export_subjects_as_csv,
              :filename => "fromthepage_subjects_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end
  
  def table_csv
    send_data(export_tables_as_csv(@work),
              :filename => "fromthepage_tables_export_#{@work.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
    
  end

  def desc_to_file(text:, dirname:, out:)
    README << text
    path = File.join dirname, 'README.txt'
    out.put_next_entry path

    README.each do |desc|
      out.write desc
    end
  end

  def export_plaintext_transcript(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_transcript.txt"

    out.put_next_entry path

    case name
    when "verbatim"
      out.write @work.verbatim_transcription_plaintext
      desc_to_file(text: "plaintext/verbatim_transcript.txt - file containing the per-document verbatim plaintext export of the transcript.\n", dirname: dirname, out: out)
    when "emended"
      out.write @work.emended_transcription_plaintext
      desc_to_file(text: "plaintext/emended_transcript.txt - file containing the per-document emended plaintext export of the transcript.\n", dirname: dirname, out: out)
    when "searchable"
      out.write @work.searchable_plaintext
      desc_to_file(text: "plaintext/searchable_transcript.txt - file containing the per-document searchable plaintext export of the transcript.\n", dirname: dirname, out: out)
    end
  end

  def export_plaintext_translation(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_translation.txt"

    out.put_next_entry path

    case name
    when "verbatim"
      out.write @work.verbatim_translation_plaintext
      desc_to_file(text: "plaintext/verbatim_translation.txt - file containing the per-document verbatim plaintext export of the translation if it is present.\n", dirname: dirname, out: out)
    when "emended"
      out.write @work.emended_translation_plaintext
      desc_to_file(text: "plaintext/emended_translation.txt - file containing the per-document emended plaintext export of the translation if it is present.\n", dirname: dirname, out: out)
    end
  end

  def export_plaintext_transcript_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_transcript_pages", "#{page.title}.txt"

    out.put_next_entry path

    case name
    when "verbatim"
      out.write page.verbatim_transcription_plaintext
      desc_to_file(text: "plaintext/verbatim_transcript_pages/#{page.title}.txt - files containing per-page verbatim plaintext export.\n", dirname: dirname, out: out)
    when "emended"
      out.write page.emended_transcription_plaintext
      desc_to_file(text: "plaintext/emended_transcript_pages/#{page.title}.txt - files containing per-page verbatim plaintext export.\n", dirname: dirname, out: out)
    end
  end

  def export_plaintext_translation_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_translation_pages", "#{page.title}.txt"

    out.put_next_entry path

    case name
    when "verbatim"
      out.write page.verbatim_translation_plaintext
      desc_to_file(text: "plaintext/verbatim_translation_pages/#{page.title}.txt - files containing per-page verbatim plaintext export.\n", dirname: dirname, out: out)
    when "emended"
      out.write page.emended_translation_plaintext
      desc_to_file(text: "plaintext/emended_translation_pages/#{page.title}.txt - files containing per-page verbatim plaintext export.\n", dirname: dirname, out: out)
    end
  end

  def export_view(name:, dirname:, out:)
    path = File.join dirname, 'html', "#{name}.html"
    out.put_next_entry path

    case name
    when "full"
      full_view = render_to_string(:action => 'show', :formats => [:html], :work_id => @work.id, :layout => false, :encoding => 'utf-8')
      out.write full_view
    when "text"
      text_view = render_to_string(:action => 'text', :formats => [:html], :work_id => @work.id, :layout => false, :encoding => 'utf-8')
      out.write text_view
    when "transcript"
      transcript_view = render_to_string(:action => 'transcript', :formats => [:html], :work_id => @work.id, :layout => false, :encoding => 'utf-8')
      out.write transcript_view
    when "translation"
      translation_view = render_to_string(:action => 'translation', :formats => [:html], :work_id => @work.id, :layout => false, :encoding => 'utf-8')
      out.write translation_view
    end
  end

  def export_html_full_pages(dirname:, out:, page:)
    path = File.join dirname, 'html', 'full_pages', "#{page.title}.html"

    out.put_next_entry path

    page_view = render_to_string('display/display_page.html.slim', :locals => {:@work => @work, :@page => page}, :layout => false)
    out.write page_view
  end

  def export_work
    dirname = @work.slug.truncate(200, omission: "")

    respond_to do |format|
      format.zip do
        buffer = Zip::OutputStream.write_buffer do |out|
          export_plaintext_transcript(name: "verbatim", dirname: dirname, out: out)
          export_plaintext_transcript(name: "emended", dirname: dirname, out: out)
          export_plaintext_transcript(name: "searchable", dirname: dirname, out: out)

          export_plaintext_translation(name: "verbatim", dirname: dirname, out: out)
          export_plaintext_translation(name: "emended", dirname: dirname, out: out)

          @work.pages.each do |page|
            export_plaintext_transcript_pages(name: "verbatim", dirname: dirname, out: out, page: page)
            export_plaintext_transcript_pages(name: "emended", dirname: dirname, out: out, page: page)

            export_plaintext_translation_pages(name: "verbatim", dirname: dirname, out: out, page: page)
            export_plaintext_translation_pages(name: "emended", dirname: dirname, out: out, page: page)
          end

          export_view(name: "full", dirname: dirname, out: out)
          export_view(name: "text", dirname: dirname, out: out)
          export_view(name: "transcript", dirname: dirname, out: out)
          export_view(name: "translation", dirname: dirname, out: out)

          @work.pages.each do |page|
            export_html_full_pages(dirname: dirname, out: out, page: page)
          end
        end

        buffer.rewind
        send_data buffer.read, filename: "#{@collection.title}-#{@work.title}.zip"
      end
    end
  end

  def export_all_works
    unless @collection.subjects_disabled
      @works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: @collection.id)
    else
      @works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: @collection.id)
    end

    # create a zip file which is automatically downloaded to the user's machine
    respond_to do |format|
      format.html
      format.zip do
        buffer = Zip::OutputStream.write_buffer do |out|
          @works.each do |work|
            @work = work
            dirname = work.slug.truncate(200, omission: "")

            export_view = render_to_string(:action => 'show', :formats => [:html], :work_id => work.id, :layout => false, :encoding => 'utf-8')
            out.put_next_entry "#{dirname}/#{work.slug.truncate(200, omission: "")}.xhtml"
            out.print export_view

            export_plaintext_transcript(name: "verbatim", dirname: dirname, out: out)
            export_plaintext_transcript(name: "emended", dirname: dirname, out: out)
            export_plaintext_transcript(name: "searchable", dirname: dirname, out: out)

            export_plaintext_translation(name: "verbatim", dirname: dirname, out: out)
            export_plaintext_translation(name: "emended", dirname: dirname, out: out)

            @work.pages.each do |page|
              export_plaintext_transcript_pages(name: "verbatim", dirname: dirname, out: out, page: page)
              export_plaintext_transcript_pages(name: "emended", dirname: dirname, out: out, page: page)

              export_plaintext_translation_pages(name: "verbatim", dirname: dirname, out: out, page: page)
              export_plaintext_translation_pages(name: "emended", dirname: dirname, out: out, page: page)
            end

            export_view(name: "full", dirname: dirname, out: out)
            export_view(name: "text", dirname: dirname, out: out)
            export_view(name: "transcript", dirname: dirname, out: out)
            export_view(name: "translation", dirname: dirname, out: out)

            @work.pages.each do |page|
              export_html_full_pages(dirname: dirname, out: out, page: page)
            end
          end
        end

        buffer.rewind
        send_data buffer.read, filename: "#{@collection.title}.zip"
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
    error_message, fts_field = ContentdmTranslator.fts_field_for_collection(@collection, license_key, contentdm_user_name, contentdm_password)

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

  def version
    version = Fromthepage::Application::Version
    database = ActiveRecord::Migrator.current_version

    render json: { software: version,
                   database: database }
  end

private

  def get_headings(collection, ids)
    field_headings = collection.transcription_fields.order(:position).where.not(input_type: 'instruction').pluck(:id)
    cell_headings = TableCell.where(work_id: ids).where("transcription_field_id not in (select id from transcription_fields)").pluck('DISTINCT header')

    @raw_headings = (field_headings + cell_headings).uniq
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    #get headings from field-based
    field_headings.each do |field_id|
      field = TranscriptionField.where(:id => field_id).first
      raw_heading = field ? field.label : field_id
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    #get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    @headings
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

      page_cells = [
        'Work Title',
        'Work Identifier',
        'Page Title',
        'Page Position',
        'Page URL',
        'Page Contributors',
        'Page Notes'
      ]

      section_cells = [
        'Section (text)',
        'Section (subjects)',
        'Section (subject categories)'
      ]

      if table_obj.sections.blank?
        csv << (page_cells + @headings)
        col_sections = false
      else
        csv << (page_cells + section_cells + @headings)
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
    all_deeds = work.deeds
    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        page_url=url_for({:controller=>'display',:action => 'display_page', :page_id => page.id, :only_path => false})
        page_notes = page.notes
          .map{ |n| "[#{n.user.display_name}<#{n.user.email}>]: #{n.body}" }.join('|').gsub('|', '//').gsub(/\s+/, ' ')
        page_contributors = all_deeds
          .select{ |d| d.page_id == page.id}
          .map{ |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
          .uniq.join('|')

        page_cells = [
          work.title,
          work.identifier,
          page.title,
          page.position,
          page_url,
          page_contributors,
          page_notes
        ]

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


  def index_for_cell(cell)
      if cell.transcription_field_id
        index = (@raw_headings.index(cell.transcription_field_id))        
      end
      index = (@raw_headings.index(cell.header)) unless index
      index = (@raw_headings.index(cell.header.strip)) unless index      

      index
  end
    

  def cell_data(array, raw_headings, data_cells)
    array.each do |cell|
      index = index_for_cell(cell)      
      target = index *2
      data_cells[target] = XmlSourceProcessor.cell_to_plaintext(cell.content)
      data_cells[target+1] = XmlSourceProcessor.cell_to_subject(cell.content)
    end
  end

end
