module ExportHelper

  def xml_to_pandoc_md(xml_text, preserve_lb=true, flatten_links=false, collection=nil, div_pad=true)

    # do some escaping of the document for markdown
    preprocessed = xml_text || ''
    # preprocessed.gsub!("[","\\[")
    # preprocessed.gsub!("]","\\]")
    preprocessed.gsub!('&', '&amp;') # escape ampersands
    preprocessed.gsub!(/&(amp;)+/, '&amp;') # clean double escapes


    doc = REXML::Document.new(preprocessed)
    doc.elements.each_with_index("//footnote") do |e,i|
      marker = "#{i+1}" #e.attributes['marker'] || '*'

      doc.root.add REXML::Text.new("\n\n#{marker}: ")
      e.children.each do |child|
        doc.root.add child
      end
      doc.root.add REXML::Text.new(" \n")

      sup = REXML::Element.new("sup")
      sup.add(REXML::Text.new(marker))
      e.replace_with(sup)
    end



    postprocessed = ""
    doc.write(postprocessed)
    html = xml_to_html(postprocessed, preserve_lb, flatten_links, collection)
    if div_pad
      doc = REXML::Document.new("<div>#{html}</div>")
    else
      doc = REXML::Document.new("#{html}")
    end

    doc.elements.each("//span") do |e|
      if e.attributes['class'] == 'line-break'
        e.replace_with(REXML::Text.new(" "))
      end
    end
    html=''
    doc.write(html)

    processed = "never ran"

    cmd = "pandoc --from html --to markdown"
    Open3.popen2(cmd) do |stdin, stdout, t| 
      stdin.print(html)
      stdin.close
      processed = stdout.read
    end

    return processed
  end



  def write_work_exports(works, out, export_user, bulk_export)

    # owner-level exports
    if bulk_export.owner_mailing_list
      export_owner_mailing_list_csv(out: out, owner: export_user)
    end

    if bulk_export.owner_detailed_activity
      export_owner_detailed_activity_csv(out: out, owner: export_user, report_arguments: bulk_export.report_arguments)
    end


    # collection-level exports
    if bulk_export.collection_activity
      export_collection_activity_csv(out: out, collection: bulk_export.collection, report_arguments: bulk_export.report_arguments)
    end

    if bulk_export.collection_contributors
      export_collection_contributors_csv(out: out, collection: bulk_export.collection, report_arguments: bulk_export.report_arguments)
    end

    if bulk_export.subject_csv_collection
      export_subject_csv(out: out, collection: bulk_export.collection)
    end

    if bulk_export.subject_details_csv_collection
      export_subject_details_csv(out: out, collection: bulk_export.collection)
    end

    if bulk_export.table_csv_collection
      export_table_csv_collection(out: out, collection: bulk_export.collection)
    end

    if bulk_export.work_metadata_csv
      export_work_metadata_csv(out: out, collection: bulk_export.collection)
    end

    if bulk_export.static
      export_static_site(dirname: 'site', out: out, collection: bulk_export.collection)
    end

    if bulk_export.work_level? || bulk_export.page_level?
      by_work = bulk_export.organization == BulkExport::Organization::WORK_THEN_FORMAT
      original_filenames = bulk_export.use_uploaded_filename
      works.each do |work|
        print "\t\tExporting work\t#{work.id}\t#{work.title}\n"
        @work = work
        if by_work
          add_readme_to_zip(work: work, out: out, by_work: by_work, original_filenames: original_filenames)
        end


        # work-specific exports
        if bulk_export.table_csv_work
          export_table_csv_work(out: out, work: work, by_work: by_work, original_filenames: original_filenames)
        end

        if bulk_export.tei_work
          export_tei(work: work, out:out, export_user:export_user, by_work: by_work, original_filenames: original_filenames)
        end

        if bulk_export.plaintext_verbatim_work
          format='verbatim'
          export_plaintext_transcript(work: work, name: format, out: out, by_work: by_work, original_filenames: original_filenames)
          export_plaintext_translation(work: work, name: format, out: out, by_work: by_work, original_filenames: original_filenames)
        end

        if bulk_export.plaintext_emended_work
          format='expanded'
          export_plaintext_transcript(work: work, name: format, out: out, by_work: by_work, original_filenames: original_filenames)
          export_plaintext_translation(work: work, name: format, out: out, by_work: by_work, original_filenames: original_filenames)
        end

        if bulk_export.plaintext_searchable_work
          format='searchable'
          export_plaintext_transcript(work: work, name: format, out: out, by_work: by_work, original_filenames: original_filenames)
        end

        if bulk_export.html_work
          %w(full text transcript translation).each do |format|
            export_view(work: work, name: format, out: out, export_user:export_user, by_work: by_work, original_filenames: original_filenames)
          end
        end

        preserve_lb = bulk_export.report_arguments['preserve_linebreaks']
        if bulk_export.facing_edition_work
          export_printable_to_zip(work, 'facing', 'pdf', out, by_work, original_filenames, preserve_lb)
        end

        if bulk_export.text_pdf_work
          export_printable_to_zip(work, 'text', 'pdf', out, by_work, original_filenames, preserve_lb)
        end

        if bulk_export.text_only_pdf_work
          export_printable_to_zip(work, 'text_only', 'pdf', out, by_work, original_filenames, preserve_lb)
        end

        if bulk_export.text_docx_work
          export_printable_to_zip(work, 'text', 'doc', out, by_work, original_filenames, preserve_lb)
        end

        # Page-specific exports

        @work.pages.each_with_index do |page,i|
          if bulk_export.plaintext_verbatim_page
            format='verbatim'
            export_plaintext_transcript_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: original_filenames, index: nil)
            export_plaintext_translation_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: original_filenames)
          end

          if bulk_export.plaintext_emended_page
            format='expanded'
            export_plaintext_transcript_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: original_filenames, index: nil)
            export_plaintext_translation_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: original_filenames)
          end  

          if bulk_export.plaintext_searchable_page
            format='searchable'
            export_plaintext_transcript_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: original_filenames, index: nil)
          end

          if bulk_export.plaintext_verbatim_zero_index_page
            format='verbatim'
            export_plaintext_transcript_pages(name: format, out: out, page: page, by_work: by_work, original_filenames: :zero_index, index: i)
          end
        end


        if bulk_export.html_page
          @work.pages.each do |page|
            export_html_full_pages(out: out, page: page, by_work: by_work, original_filenames: original_filenames)
          end
        end
      end
    end
  end


  def work_to_xhtml(work)
    @work = Work.includes(pages: [{notes: :user}, {page_versions: :user}]).find_by(id: work.id)
    render_to_string :layout => false, :template => "export/show.html.erb"
  end

  def work_to_tei(work, exporting_user)
    params ||= {}
    params[:format] = 'xml'# if params[:format].blank?

    @work = work
    @context = ExportContext.new

    @user_contributions =
      User.find_by_sql("SELECT  user_id user_id,
                                users.login login,
                                users.real_name real_name,
                                users.display_name display_name,
                                users.guest guest,
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

    @person_articles = @all_articles.joins(:categories).where(categories: {title: 'People'}).to_a
    @place_articles = @all_articles.joins(:categories).where(categories: {title: 'Places'}).to_a
    @other_articles = @all_articles.joins(:categories).where.not(categories: {title: 'People'})
                      .where.not(categories: {title: 'Places'}).to_a
    @other_articles.each do |subject|
      subjects = expand_subject(subject)
      if subjects.count > 1
        subjects[1..].each do |expanded|
          if expanded.categories.where(title: 'People').present?
            @person_articles << expanded
          elsif expanded.categories.where(title: 'Places').present?
            @place_articles << expanded
          else
            @other_articles << expanded
          end
        end
      end
    end

    @person_articles.uniq!
    @place_articles.uniq!
    @other_articles.uniq!

    ### Catch the rendered Work for post-processing
    if defined? render_to_string
      thingy = self
    else
      thingy = ApplicationController.new
    end

    xml = thingy.render_to_string(
      layout: false, 
      template: "export/tei.html.erb",
      assigns: {
        work: @work,
        context: @context,
        user_contributions: @user_contributions,
        work_versions: @work_versions,
        all_articles: @all_articles,
        person_articles: @person_articles,
        place_articles: @place_articles,
        other_articles: @other_articles,
        collection: @work.collection,
        user: exporting_user
      })
    post_process_xml(xml, @work)

    xml
  end



  def page_id_to_xml_id(id, translation=false)
    return "" if id.blank?
    
    if translation
      "TTP#{id}"
    else
      "OTP#{id}"
    end
  end

  def tei_taxonomy(categories, subjects)
    tei = "<taxonomy>\n"
    seen_subjects = []
    categories.each do |category|
      tei << category_to_tei(category, subjects, seen_subjects)
    end
    tei << "</taxonomy>\n"
    tei = REXML::Document.new(tei).to_s
    
    tei
  end

  def category_to_tei(category, subjects, seen_subjects) 
    has_content = false
    tei = ""
    tei << "<category xml:id=\"C#{category.id}\">\n"
    tei << "<catDesc>#{ERB::Util.html_escape(category.title)}</catDesc>\n"
    category.articles.where("id in (?)", subjects.map {|s| s.id}).each do |subject|
      has_content = true
      if seen_subjects.include?(subject)
        tei << seen_subject_to_tei(subject, category)
      else
        tei << subject_to_tei(subject)
        seen_subjects << subject
      end
    end
    category.children.each do |child|
      has_content = true
      tei << category_to_tei(child, subjects, seen_subjects)
    end
    tei << "</category>\n"

    has_content ? tei : ""
  end

  def expand_subject(subject)
    subjects = [subject]

    parts = subject.title.split(/(\. |--)/)
    0.upto(parts.size/2 - 1) do |i|
      higher_subject_title = parts[0..(2*i)].join
      higher_subject = subject.collection.articles.where(title: higher_subject_title).first
      if higher_subject
        subjects << higher_subject
      end
    end

    subjects
  end
  
  def subject_to_tei(subject)
    tei = format_subject_to_tei(subject)
    tei
  end

  def format_subject_to_tei(subject)
    tei = "          <category xml:id=\"S#{subject.id}\">\n"
    tei << "            <catDesc>\n"
    tei << "              <term>#{ERB::Util.html_escape(subject.title)}</term>\n"
    unless subject.uri.blank?
      tei << "              <idno>#{subject.uri.encode(xml: :text)}</idno>\n"
    end
    tei << '              <note type="categorization">Categories:'
    subject.categories.each do |category|
      tei << '<ab>'
      category.ancestors.reverse.each do |parent|
        if parent.root? 
          category_class = "#category #root"
        else
          category_class = "#category #branch"
        end
        tei << "<ptr ana=\"#{category_class}\" target=\"#C#{parent.id}\">#{ERB::Util.html_escape(parent.title)}</ptr> -- "
      end
      tei << "<ptr ana=\"#category #leaf#{' #root' if category.root?}\" target=\"#C#{category.id}\">#{ERB::Util.html_escape(category.title)}</ptr>"
      tei << "</ab>\n"
    end
    tei << "              </note>\n"
    unless subject.latitude.blank?
      tei << "              <note type=\"geography\">\n"
      tei << "                <geo>#{subject.latitude}, #{subject.longitude}</geo>\n"
      tei << "              </note>\n"
    end

    tei << "              <gloss>#{xml_to_export_tei(subject.xml_text,ExportContext.new, "SD#{subject.id}")}</gloss>\n" unless subject.source_text.blank?
    tei << "            </catDesc>\n"
    tei << "          </category>\n"

    tei
  end



  def seen_subject_to_tei(subject, parent_category)
    tei = "<category xml:id=\"C#{parent_category.id}S#{subject.id}\">\n"
    tei << "<catDesc>\n"
    tei << "<term><rs ref=\"S#{subject.id}\">#{ERB::Util.html_escape(subject.title)}</rs></term>\n"
    tei << "</catDesc>\n"
    tei << "</category>\n"

    tei
    
  end

  def xml_to_export_tei(xml_text, context, page_id = "", add_corrsp=false)

    return "" if xml_text.blank?
#    xml_text.gsub!(/\n/, "")
    xml_text.gsub!('ISO-8859-15', 'UTF-8')
    xml_text.gsub!('&', '&amp;')
    xml_text.gsub!('&amp;amp;', '&amp;')

    # xml_text = titles_to_divs(xml_text, context)
    doc = REXML::Document.new(xml_text)
    #paras_string = ""

    my_display_html = ""
    doc.elements.each_with_index("//p") do |e,i|
      transform_links(e)
      transform_expansions(e)
      transform_regularizations(e)
      transform_marginalia_and_catchwords(e)
      transform_footnotes(e)
      transform_lb(e)
      e.add_attribute("xml:id", "#{page_id_to_xml_id(page_id, context.translation_mode)}P#{i}")
      if add_corrsp
        e.add_attribute("corresp", "#{page_id_to_xml_id(page_id, !context.translation_mode)}P#{i}")
      end
      my_display_html << e.to_s
    end

    return my_display_html.gsub('<lb/>', "<lb/>\n").gsub('</p>', "\n</p>\n\n").gsub('<p>', "<p>\n").encode('utf-8')
  end

  def transform_expansions(p_element)
    p_element.elements.each('//expan') do |expan|
      orig = expan.attributes['orig']
      unless orig.blank?
        choice = REXML::Element.new("choice")
        tei_expan = REXML::Element.new("expan")
        expan.children.each { |c| tei_expan.add(c) }
        choice.add(tei_expan)
        unless orig.blank?
          tei_abbr = REXML::Element.new("abbr")
          tei_abbr.add_text(orig)
          choice.add(tei_abbr)
        end
        expan.replace_with(choice)
      end
    end

    p_element.elements.each('//abbr') do |abbr|
      expan = abbr.attributes['expan']
      unless expan.blank?
        choice = REXML::Element.new("choice")
        tei_expan = REXML::Element.new("expan")
        tei_expan.add_text(expan)
        choice.add(tei_expan)

        tei_abbr = REXML::Element.new("abbr")
        abbr.children.each { |c| tei_abbr.add(c) }
        choice.add(tei_abbr)

        abbr.replace_with(choice)
      end
    end

  end

  def transform_regularizations(p_element)
    p_element.elements.each('//reg') do |reg|
      orig = reg.attributes['orig']
      unless orig.blank? || reg.parent.name == 'choice'
        choice = REXML::Element.new("choice")
        tei_reg = REXML::Element.new("reg")
        reg.children.each { |c| tei_reg.add(c) }
        choice.add(tei_reg)
        unless orig.blank?
          tei_orig = REXML::Element.new("orig")
          tei_orig.add_text(orig)
          choice.add(tei_orig)
        end
        reg.replace_with(choice)
      end
    end
  end

  def transform_marginalia_and_catchwords(p_element)
    p_element.elements.each('//marginalia') do |e|
      e.name='note'
      e.add_attribute('type', 'marginalia')
    end
    
    p_element.elements.each('//catchword') do |e|
      e.name='fw'
      e.add_attribute('type', 'catchword')
    end
  end

  def transform_footnotes(p_element)
    p_element.elements.each('//footnote') do |e|
      marker = e.attributes['marker']
      
      e.name='note'
      e.delete_attribute('marker')
      e.add_attribute('type', 'footnote')
      e.add_attribute('n', marker)
    end
  end

  def transform_lb(p_element)
    # while we support text within an LB tag to encode line 
    # continuation sigla, TEI doesn't and recommends the sigil be part of the text before the LB
    p_element.elements.each('//lb') do |e|
      if e['break'] == 'no'
        unless e.text.blank?
          previous_element = e.previous_sibling
          e.children.each do |child|
            previous_element.next_sibling = child
          end
        end
      end
    end
    
  end


  # def titles_to_divs(xml_text, context)
    # logger.debug("FOO #{context.div_stack.count}\n")
    # xml_text.scan(/entryHeading title=\".s*\" depth=\"(\d)\"")
  # end

  def transform_links(p_element)
    p_element.elements.each('//link') do |link|
      rs = REXML::Element.new("rs")

      id = link.attributes['target_id']
      rs.add_attribute("ref", "#S#{id}")

      link.children.each { |c| rs.add(c) }
      link.replace_with(rs)

    end
    p_element.elements.each('//sensitive') do |sensitive|
      gap = REXML::Element.new("gap")

      gap.add_attribute("reason", "redacted")
      sensitive.replace_with(gap)
    end
    p_element.elements.each('//entryHeading') do |entryHeading|
      gap = REXML::Element.new("head")

      gap.add_attribute("depth", entryHeading.attributes["depth"])
      gap.add_text(entryHeading.attributes["title"])
      entryHeading.replace_with(gap)
    end
    p_element.elements.each('//a') do |a|
      rs = REXML::Element.new("rs")
      href = a.attributes['href']

      rs.add_attribute("ref", href)
      a.children.each { |c| rs.add(c) }
      a.replace_with(rs)
    end
    p_element.elements.each('//strike') do |strike|
      del = REXML::Element.new("del")

      del.add_attribute("rend", "overstrike")
      strike.children.each { |c| del.add(c) }
      strike.replace_with(del)
    end
    p_element.elements.each('//s') do |strike|
      del = REXML::Element.new("del")

      del.add_attribute("rend", "overstrike")
      strike.children.each { |c| del.add(c) }
      strike.replace_with(del)
    end
    p_element.elements.each('//u') do |u|
      hi = REXML::Element.new("hi")

      hi.add_attribute("rend", "underline")
      u.children.each { |c| hi.add(c) }

      u.replace_with(hi)
    end
    p_element.elements.each('//i') do |i|
      hi = REXML::Element.new("hi")

      hi.add_attribute("rend", "italic")
      i.children.each { |c| hi.add(c) }

      i.replace_with(hi)
    end
    p_element.elements.each('//sup') do |sup|
      add = REXML::Element.new("add")

      add.add_attribute("place", "above")
      sup.children.each { |c| add.add(c) }
      sup.replace_with(add)
    end
  end

  def post_process_xml(xml, work)
    if work.pages_are_meaningful?
      return xml
    else
      doc = REXML::Document.new(xml)
      doc_body = doc.get_elements('//body').first
      
      # Process Sections
      current_depth = 1
      sections = []
      
      doc_body.children.each do |e|
      
        if(e.node_type != :text && e.get_elements('head').length > 0)
          header = e.get_elements('head').first
          
          # Create the new section
          section = REXML::Element.new('section')
          section.add_attribute('depth', header.attributes['depth']) 

          # Handle where to put the new section
          if sections.empty?
            # Inserts the new section into the doc before the current element
            e.parent.insert_before(e, section)
            sections.push(section)
            # section.add(e)
          # elsif current_depth < header.attributes['depth'].to_i
          #   sections.first.add(section)
          #   # section.add(e)
          # elsif current_depth == header.attributes['depth'].to_i
          #   sections.pop()
          #   sections.first.add(section)
          #   # section.add(e)
          else
            ## This still isn't working right

          end

          # Update the accumulator
          sections.push(section)
          current_depth = section.attributes['depth'].to_i
        end

        # Adds the current element to the new section at the right location
        sections.first.add(e) unless sections.empty?
      
      end
      
      return doc
    end
  end


  def work_metadata_contributions(work)
    {
      contributors: work_metadata_contributors_to_array(work),
      data: work_metadata_to_hash(work),
    }
  end

  def page_field_contributions(page)
    {
      contributors: page_contributors_to_array(page),
      data: field_data_to_hash(page),
    }
  end



  def work_metadata_to_hash(work)
    collection=work.collection
    fields = {}
    collection.metadata_fields.each { |field| fields[field.id] = field}
    response_array = []
    if work.metadata_description
      metadata = JSON.parse(work.metadata_description)
      # TODO remember description status!
      metadata.each do |metadata_hash|
        value = metadata_hash['value']
        unless value.blank?
          element = {label: metadata_hash['label'], value: value}
          element[:config] = iiif_strucured_data_field_config_url(metadata_hash['transcription_field_id'])

          response_array << element
        end
      end
    end

    response_array
  end

  def field_data_to_hash(page)
    collection=page.collection
    fields = {}
    collection.transcription_fields.each { |field| fields[field.label] = field}
    spreadsheet = collection.transcription_fields.detect { |field| field.input_type == 'spreadsheet'}
    columns = {}
    if spreadsheet
      spreadsheet.spreadsheet_columns.each { |column| columns[column.label] = column}
    end

    response_array = []
    page.table_cells.each do |cell| 
      unless columns[cell.header]

        field = fields[cell.header]
        element = {label: cell.header, value: cell.content}
        if field #field-based project
          element[:config] = iiif_strucured_data_field_config_url(field.id)
        else
          element[:row] = cell.row
          element[:config] = 'N/A'
        end

        response_array << element
      end
    end

    spreadsheet_array = []
    page.table_cells.includes(:transcription_field).group_by(&:row).each do |row, cell_array|
      row = []
      cell_array.each do |cell|
        # eliminate header cells
        unless fields[cell.header]
          unless cell.content.blank?
            element = {label: cell.header, value: cell.content}
            column = columns[cell.header]
            unless column.blank?
              element[:config] = iiif_strucured_data_column_config_url(column.id)
            end
            row << element
          end
        end
      end
      spreadsheet_array << row
    end

    unless spreadsheet_array.flatten.empty?
      spreadsheet_field = collection.transcription_fields.where(input_type: 'spreadsheet').first
      element = {
        data: spreadsheet_array
      }
      if spreadsheet_field
        element[:config] = iiif_strucured_data_field_config_url(spreadsheet_field.id)
      end

      response_array << element
    end

    response_array
  end


  def spreadsheet_column_config(column, include_within)
    column_config = {
      label: column.label, 
      input_type: column.input_type, 
      position: column.position,
      profile: 'https://github.com/benwbrum/fromthepage/wiki/Structured-Data-API-for-Harvesting-Crowdsourced-Contributions#structured-data-spreadsheet-column-configuration-response'
    }
    if column.options
      column_config[:options] = column.options.split(";")
    end
    column_config['@id'] = iiif_strucured_data_column_config_url(column.id)

    if include_within
      column_config['within'] = iiif_strucured_data_field_config_url(column.transcription_field.id)
    end

    column_config
  end

  def transcription_field_config(field, include_within)
    element = {
      label: field.label, 
      input_type: field.input_type, 
      position: field.position, 
      line: field.line_number,
      profile: 'https://github.com/benwbrum/fromthepage/wiki/Structured-Data-API-for-Harvesting-Crowdsourced-Contributions#structured-data-field-configuration-response'
    }
    element['@id'] = iiif_strucured_data_field_config_url(field.id)
    if field.options
      if field.input_type == 'multiselect'
        element[:options] = field.options.split(/[\n\r]+/)
      else
        element[:options] = field.options.split(";")
      end
    end
    if field.page_number
      element[:page_number] = field.page_number
    end
    if field.input_type == 'spreadsheet'
      columns=[]
      field.spreadsheet_columns.each do |column|
        columns << spreadsheet_column_config(column, false)
      end

      element[:spreadsheet_columns] = columns
    end
    if include_within
      if field.field_type == TranscriptionField::FieldType::TRANSCRIPTION
        element[:within] = iiif_page_strucured_data_config_url(field.collection.id)
      else
        element[:within] = iiif_work_strucured_data_config_url(field.collection.id)
      end
    end

    element
  end

  def field_configuration_to_array(collection, field_type)
    array = []
    if field_type == TranscriptionField::FieldType::TRANSCRIPTION
      fields = collection.transcription_fields
    else
      fields = collection.metadata_fields
    end
    fields.each do |field|
      array << transcription_field_config(field, false)
    end

    array
  end

  def page_contributors_to_array(page)
    array = []

    user_ids = page.deeds.where(deed_type: DeedType.transcriptions_or_corrections).pluck(:user_id).uniq
    User.find(user_ids).each do |user|
      element = { 'userName' => user.display_name}
      element['realName'] = user.real_name unless user.real_name.blank?
      element[:orcid] = user.real_name unless user.orcid.blank?
      array << element
    end

    array
  end

  def work_metadata_contributors_to_array(work)
    array = []

    user_ids = work.deeds.where(deed_type: DeedType.metadata_creation_or_edits).pluck(:user_id).uniq
    User.find(user_ids).each do |user|
      element = { 'userName' => user.display_name}
      element['realName'] = user.real_name unless user.real_name.blank?
      element[:orcid] = user.real_name unless user.orcid.blank?
      array << element
    end

    array
  end



end
