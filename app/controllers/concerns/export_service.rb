module ExportService
  include AbstractXmlHelper

  def add_readme_to_zip(dirname:, out:)
    readme = "#{Rails.root}/doc/zip/README"
    file = File.open(readme, "r")
    path = File.join dirname, 'README.txt'
    out.put_next_entry path
    out.write file.read
  end

  def export_printable_to_zip(work, edition, output_format, dirname, out)
    case edition
    when "facing"
      path = File.join dirname, 'printable', "facing_edition.pdf"
    when "text"
      path = File.join dirname, 'printable', "text.#{output_format}"
    end

    tempfile = export_printable(work, edition, output_format)
    out.put_next_entry(path)
    out.write(IO.read(tempfile))
  end

  def export_printable(work, edition, format)
    # render to a string
    rendered_markdown = 
      ApplicationController.new.render_to_string(
        :template => '/export/facing_edition.html', 
        :layout => false,
        :assigns => {
          :collection => work.collection,
          :work => work,
          :edition_type => edition,
          :output_type => format
        }
      )

    # write the string to a temp directory
    temp_dir = File.join(Rails.root, 'public', 'printable')
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    time_stub = Time.now.gmtime.iso8601.gsub(/\D/,'')
    temp_dir = File.join(temp_dir, time_stub)
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    file_stub = "#{@work.slug.gsub('-','_')}_#{time_stub}"
    md_file = File.join(temp_dir, "#{file_stub}.md")
    if format == 'pdf'
      output_file = File.join(temp_dir, "#{file_stub}.pdf")
    elsif format == 'doc'
      output_file = File.join(temp_dir, "#{file_stub}.docx")      
    end

    File.write(md_file, rendered_markdown)

    # run pandoc against the temp directory
    log_file = File.join(temp_dir, "#{file_stub}.log")
    cmd = "pandoc --from markdown+superscript -o #{output_file} #{md_file} --pdf-engine=xelatex --verbose > #{log_file} 2>&1"
    puts cmd
    logger.info(cmd)
    system(cmd)
    puts File.read(log_file)

    output_file
  end



  def export_work_metadata_csv(dirname:, out:, collection:)
    path = "work_metadata.csv"
    out.put_next_entry(path)
    out.write(export_work_metadata_as_csv(collection))
  end

  def export_subject_csv(dirname:, out:, collection:)
    path = "subject_index.csv"
    out.put_next_entry(path)
    out.write(collection.export_subject_index_as_csv)
  end

  def export_table_csv_collection(dirname:, out:, collection:)
    path = "fields_and_tables.csv"
    out.put_next_entry(path)
    out.write(export_tables_as_csv(collection))
  end

  def export_table_csv_work(dirname:, out:, work:)
    path = File.join dirname, 'csv', "fields_and_tables.csv"
    out.put_next_entry(path)
    out.write(export_tables_as_csv(work))
  end

  def export_tei(dirname:, out:, export_user:)
    path = File.join dirname, 'tei', "tei.xml"
    out.put_next_entry path
    out.write work_to_tei(@work, export_user)
  end

  def export_plaintext_transcript(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_transcript.txt"

    case name
    when "verbatim"
      out.put_next_entry path
      out.write @work.verbatim_transcription_plaintext
    when "expanded"
      if @work.collection.subjects_disabled
        out.put_next_entry path
        out.write @work.emended_transcription_plaintext
      end
    when "searchable"
      out.put_next_entry path
      out.write @work.searchable_plaintext
    end
  end

  def export_plaintext_translation(name:, dirname:, out:)
    path = File.join dirname, 'plaintext', "#{name}_translation.txt"

    if @work.supports_translation?
      case name
      when "verbatim"
        out.put_next_entry path
        out.write @work.verbatim_translation_plaintext
      when "expanded"
        if @work.collection.subjects_disabled
          out.put_next_entry path
          out.write @work.emended_translation_plaintext
        end
      end
    end
  end

  def export_plaintext_transcript_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_transcript_pages", "#{page.title}.txt"

    case name
    when "verbatim"
      out.put_next_entry path
      out.write page.verbatim_transcription_plaintext
    when "expanded"
      if page.collection.subjects_disabled
        out.put_next_entry path
        out.write page.emended_transcription_plaintext
      end
    when "searchable"
      out.put_next_entry path
      out.write page.search_text      
    end
  end

  def export_plaintext_translation_pages(name:, dirname:, out:, page:)
    path = File.join dirname, 'plaintext', "#{name}_translation_pages", "#{page.title}.txt"

    if @work.supports_translation?
      case name
      when "verbatim"
        out.put_next_entry path
        out.write page.verbatim_translation_plaintext
      when "expanded"
        if page.collection.subjects_disabled
          out.put_next_entry path
          out.write page.emended_translation_plaintext
        end
      end
    end
  end

  def export_view(name:, dirname:, out:, export_user:)
    path = File.join dirname, 'html', "#{name}.html"

    case name
    when "full"
      full_view = ApplicationController.new.render_to_string(
        :template => 'export/show', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write full_view
    when "text"
      text_view = ApplicationController.new.render_to_string(
        :template => 'export/text', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write text_view
    when "transcript"
      transcript_view = ApplicationController.new.render_to_string(
        :template => 'export/transcript', 
        :formats => [:html], 
        :work_id => @work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => @work.collection,
          :work => @work,
          :export_user => export_user
        })
      out.put_next_entry path
      out.write transcript_view
    when "translation"
      if @work.supports_translation?
        translation_view = ApplicationController.new.render_to_string(
          :template => 'export/translation', 
          :formats => [:html], 
          :work_id => @work.id, 
          :layout => false, 
          :encoding => 'utf-8',
          :assigns => {
            :collection => @work.collection,
            :work => @work,
            :export_user => export_user
          })
        out.put_next_entry path
        out.write translation_view
      end
    end
  end

  def export_html_full_pages(dirname:, out:, page:)
    path = File.join dirname, 'html', 'full_pages', "#{page.title}.html"

    out.put_next_entry path

    page_view = xml_to_html(page.xml_text, true, false, page.work.collection)
    out.write page_view
  end

  GEMFILE_CONTENTS = <<EOF
source "https://rubygems.org"
# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#
# This will help ensure the proper Jekyll version is running.
# Happy Jekylling!
gem "jekyll", "~> 4.0.1"
# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem "minima", "~> 2.5"
gem "minimal-mistakes-jekyll"
# If you want to use GitHub Pages, remove the "gem "jekyll"" above and
# uncomment the line below. To upgrade, run `bundle update github-pages`.
# gem "github-pages", group: :jekyll_plugins
# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :install_if => Gem.win_platform?
EOF

  SUBJECT_LAYOUT_CONTENTS =<<EOF_LAYOUT
---
layout: archive
---

{{ content }}

<ul>
  {% for page_link in page.page_links %}
    <li>
      <a href="/{{page_link.work_url}}REPLACEME{{page_link.page_anchor}}">{{ page_link.work_title }} {{ page_link.page_title }}</a> 
    </li>
  {% endfor %}
</ul>
EOF_LAYOUT


  WORK_LAYOUT_CONTENTS =<<EOF_WORK_LAYOUT
---
layout: archive
---

{{ content }}

<dl>
  {% for metadata in page.metadata %}
    <dt class="fas">
      {{ metadata.label }}
    </dt>
    <dd>
      {{ metadata.value }}
    </dd>
  {% endfor %}
</dl>
EOF_WORK_LAYOUT

  LISTING_LAYOUT_CONTENTS =<<EOF_LISTING_LAYOUT
---
layout: archive
---

{{ content }}


{% assign tree = page.listing %}
{% include tree.html %}

EOF_LISTING_LAYOUT

  TREE_INCLUDE_CONTENTS =<<EOF_TREE_INCLUDE
<ul>
  {% for item in tree %}
    <li>
      {% if item.url %}
        <a href="{{ item.url }}">
          {{ item.title }}
        </a>
      {% else %}
          {{ item.title }}
      {% endif %}
    </li>

    {% if item.has_children %}
      {% assign tree = item.children %}
      {% include tree.html %}
    {% endif %}
  {% endfor %}
</ul>
EOF_TREE_INCLUDE

  def category_to_tree(category) 
    element = {}
    element['title'] = category.title
    children = []

    if category.children.any? || category.articles.any?
      element['has_children'] = true
    end
    category.children.each do |child|
      children << category_to_tree(child)
    end

    category.articles.each do |subject|
      node = {
        'title' => subject.title,
        'url' => "/pages/subjects/#{subject.id}"
      }
      children << node
    end

    element['children'] = children

    element
  end


  def export_static_site(dirname:, out:, collection:)
    # site-wide files first

    path = File.join dirname, "Gemfile"
    out.put_next_entry(path)
    out.write(GEMFILE_CONTENTS)

    path = File.join dirname, '_layouts', 'subject.html'
    out.put_next_entry(path)
    out.write(SUBJECT_LAYOUT_CONTENTS.gsub('REPLACEME', '#'))

    path = File.join dirname, '_layouts', 'work.html'
    out.put_next_entry(path)
    out.write(WORK_LAYOUT_CONTENTS)

    path = File.join dirname, '_layouts', 'listing.html'
    out.put_next_entry(path)
    out.write(LISTING_LAYOUT_CONTENTS)

    path = File.join dirname, '_includes', 'tree.html'
    out.put_next_entry(path)
    out.write(TREE_INCLUDE_CONTENTS)

    path = File.join dirname, "index.md"
    out.put_next_entry(path)
    out.write("---\n"+collection.intro_block)

    path = File.join dirname, "_config.yml"
    out.put_next_entry(path)
    site_config = {
      'title' => collection.title,
      'email' => collection.owner.email,
      'description' => collection.intro_block,
      'theme' => 'minimal-mistakes-jekyll',
      'plugins' => ['jekyll-feed'], # todo jekyll-remote-theme
      'defaults' => [
        { 'scope' => 
          { 
            'path' => ''
          },
          'values' => 
          { 
            'layout' => 'home', 
            'sidebar' => 
            { 
              'nav' => 'main'
            }
          }
        }
      ]
    }
    out.write(site_config.to_yaml)

    path = File.join dirname, "_data", "navigation.yml"
    out.put_next_entry(path)

    work_nav = []
    collection.works.sort.each do |work|
      work_nav << {
        'title' => work.title,
        'url' => "/pages/works/#{work.slug}"
      }
    end
 #   work_nav.sort!

    subject_nav = []
    collection.articles.sort.each do |subject|
      subject_nav << {
        'title' => subject.title,
        'url' => "/pages/subjects/#{subject.id}"
      }
    end
#    subject_nav.sort!

    navigation = {
      'main' =>
        [
          { 
            'title' => 'Works',
            'url' => '/pages/work-list',
            'children' => work_nav
          },
          {
            'title' => 'Subjects',
            'url' => '/pages/subject-list',
            'children' => subject_nav
          },
          {
            'title' => 'About',
            'url' => '/pages/about'
          }
        ]
    }
    out.write(navigation.to_yaml)

    # listing pages
    path = File.join dirname, "pages", "work-list.md"
    out.put_next_entry(path)
    work_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Works'
    }
    work_listing_frontmatter['listing'] = collection.works.map do |work| 
      { 
        'title' => work.title, 
        'url' => "/pages/works/#{work.slug}"
      } 
    end
    out.write(work_listing_frontmatter.to_yaml+"\n---\n")


    path = File.join dirname, "pages", "subject-list.md"
    out.put_next_entry(path)
    subject_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Subjects'
    }
    tree = []
    collection.categories.each do |category|
      tree << category_to_tree(category)
    end

    uncategorized_articles = collection.articles.where.not(:id => collection.articles.joins(:categories).pluck(:id))
    if uncategorized_articles.count > 0
      children = []
      uncategorized_articles.each do |subject|
        children << {
          'title' => subject.title,
         'url' => "pages/subjects/#{subject.id}"
         }
      end

      uncategorized = { 
        'title' => 'Uncategorized',
        'has_children' => true,
        'children' => children
      }
      tree << uncategorized
    end

    subject_listing_frontmatter['listing'] = tree
    out.write(subject_listing_frontmatter.to_yaml+"\n---\n")


    # listing pages
    path = File.join dirname, "pages", "about.md"
    out.put_next_entry(path)
    contributor_listing_frontmatter = {
      'layout' => 'listing',
      'title' => 'Contributors'
    }
    contributor_ids = collection.deeds.group(:user_id).count.sort{|a,b| b[1] <=> a[1]}.map{|e| e[0]}
    listing = []
    contributor_ids.each do |user_id|
      user = User.find(user_id)
      if user.real_name.blank?
        listing << { 'title' => user.display_name}
      else
        listing << { 'title' => user.real_name}
      end
    end
    contributor_listing_frontmatter['listing'] = listing
    out.write(contributor_listing_frontmatter.to_yaml+"\n---\n")



    # work on pages now
    collection.works.each do |work|
      path = File.join dirname, 'pages', 'works', "#{work.slug}.md"
      out.put_next_entry path

    # if dc_source
    #   manifest.metadata = [dc_source]
    # else
    #   manifest.metadata = []
    # end
    # if work.original_metadata
    #   manifest.metadata += JSON[work.original_metadata]
    # end
    # work_metadata = work.attributes.except("id", "title", "description","created_on", "transcription_version", "owner_user_id", "restrict_scribes", "transcription_version", "transcription_conventions", "collection_id", "scribes_can_edit_titles", "supports_translation", "translation_instructions", "pages_are_meaningful", "ocr_correction", "slug", "picture", "featured_page", "original_metadata", "next_untranscribed_page", "in_scope").delete_if{|k,v| v.blank?}

    # work_metadata.each_pair { |label,value| manifest.metadata << { "label" => label.titleize, "value" => value.to_s } }

      metadata = []
      if work.original_metadata
        metadata += JSON[work.original_metadata]
      end
      work_metadata = work.attributes.except("id", "title", "next_untranscribed_page_id", "description","created_on", "transcription_version", "owner_user_id", "restrict_scribes", "transcription_version", "transcription_conventions", "collection_id", "scribes_can_edit_titles", "supports_translation", "translation_instructions", "pages_are_meaningful", "ocr_correction", "slug", "picture", "featured_page", "original_metadata", "in_scope").delete_if{|k,v| v.blank?}

      work_metadata.each_pair { |label,value| metadata << { "label" => label.titleize, "value" => value.to_s } }

      frontmatter = {
        'title' => work.title,
        'layout' => 'work',
        'metadata' => metadata
      }

      text = ApplicationController.new.render_to_string(
        :template => 'export/show', 
        :formats => [:html], 
        :work_id => work.id, 
        :layout => false, 
        :encoding => 'utf-8',
        :assigns => {
          :collection => work.collection,
          :work => work,
          :export_user => nil,
          :target => :jekyll
        }
      )
      text.gsub!(/^\s+/,'')
      markdown = frontmatter.to_yaml+"\n---\n"+text
      out.write(markdown)

    end

    collection.articles.each do |subject|
      path = File.join dirname, 'pages', 'subjects', "#{subject.id}.md"
      out.put_next_entry path

      text = xml_to_html(subject.xml_text, false, :jekyll, collection) # TODO convert to HTML
  #     page_links: 
  # - work_title: Volume 3 Book 1
  #   work_url: pages/works/jeremiah-white-graves-diary-volume-3-book-01
  #   page_title: January 22, 1866 - January 31, 1866
  #   page_anchor: page-1356954
      page_links = []
      subject.page_article_links.each do |link|
        page_links << {
          'work_title' => link.page.work.title,
          'work_url' => "pages/works/#{link.page.work.slug}",
          'page_title' => link.page.title,
          'page_anchor' => "page-#{link.page_id}"
        }
      end
      frontmatter = {
        'title' => subject.title,
        'layout' => 'subject',
        'page_links' => page_links
      }


      markdown = frontmatter.to_yaml+"\n---\n"+text
      out.write(markdown)

    end

    # produce listing files



  end



private

  def spreadsheet_heading_to_indexable(field_id, column_label)
    {field_id => column_label}
  end

  def spreadsheet_column_to_indexable(column)
    spreadsheet_heading_to_indexable(column.transcription_field_id, column.label)
  end

  def get_headings(collection, ids)
    field_headings = collection.transcription_fields.order(:line_number, :position).where.not(input_type: 'instruction').pluck(:id)
    orphan_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id not in (select id from transcription_fields)").pluck(Arel.sql('DISTINCT header'))
    renamed_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id is not null").pluck(Arel.sql('DISTINCT header')) - collection.transcription_fields.pluck(:label)
    markdown_cell_headings = TableCell.where(work_id: ids).where("transcription_field_id is null").pluck(Arel.sql('DISTINCT header'))
    cell_headings = orphan_cell_headings + markdown_cell_headings 

    @raw_headings = (field_headings + cell_headings + renamed_cell_headings).uniq
    @indexable_headings = @raw_headings.map { |e| e.is_a?(String) ? e.downcase : e }
    @headings = []

    @page_metadata_headings = collection.page_metadata_fields
    @headings += @page_metadata_headings

    #get headings from field-based
    field_headings.each do |field_id|
      field = TranscriptionField.where(:id => field_id).first
      if field && field.input_type == 'spreadsheet'
        raw_field_index = @raw_headings.index(field_id)
        field.spreadsheet_columns.each do |column|
          raw_field_index += 1
          raw_heading = "#{field.label} #{column.label}"
          @raw_headings.insert(raw_field_index, spreadsheet_column_to_indexable(column))
          @headings << "#{raw_heading} (text)"
          @headings << "#{raw_heading} (subject)"
        end
        @raw_headings.delete(field_id)
      else
        raw_heading = field ? field.label : field_id
        @headings << "#{raw_heading} (text)"
        @headings << "#{raw_heading} (subject)"
      end
    end
    #get headings from non-field-based
    cell_headings.each do |raw_heading|
      @headings << "#{raw_heading} (text)"
      @headings << "#{raw_heading} (subject)"
    end
    @headings
  end


  def export_work_metadata_as_csv(collection)
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      static_headers = [
        'Title', 
        'Collection', 
        'Document Sets', 
        'Uploaded Filename', 
        'FromThePage ID',
        'FromThePage Slug',
        'FromThePage URL',
        'Identifier',
        'Originating Manifest ID',
        'Total Pages',
        'Pages Transcribed',
        'Pages Corrected',
        'Pages Indexed',
        'Pages Translated',
        'Pages Needing Review',
        'Pages Marked Blank'
      ]

      raw_metadata_strings = collection.works.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings.map{|raw| raw.nil? ? [] : JSON.parse(raw).map{|element| element["label"] } }.flatten.uniq

      csv << static_headers + metadata_headers

      collection.works.includes(:document_sets, :work_statistic, :sc_manifest).reorder(:id).each do |work| 
        row = [
          work.title,
          work.collection.title,
          work.document_sets.map{|ds| ds.title}. join('|'),
          work.uploaded_filename,
          work.id,
          work.slug,
          collection_read_work_url(collection.owner, collection, work),
          work.identifier,
          work.sc_manifest.nil? ? '' : work.sc_manifest.at_id,
          work.work_statistic.total_pages,
          work.work_statistic.transcribed_pages,
          work.work_statistic.corrected_pages,
          work.work_statistic.annotated_pages,
          work.work_statistic.translated_pages,
          work.work_statistic.needs_review,
          work.work_statistic.blank_pages
        ]

        unless work.original_metadata.blank?
          metadata = {}
          JSON.parse(work.original_metadata).each {|e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            # look up the value for this index
            row << metadata[header]
          end
        end

        csv << row
      end
    end

    csv_string
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
        'Page Notes',
        'Page Status'
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
    csv_string
  end

  def generate_csv(work, csv, col_sections)
    all_deeds = work.deeds
    work.pages.includes(:table_cells).each do |page|
      unless page.table_cells.empty?
        has_spreadsheet = page.table_cells.detect { |cell| cell.transcription_field && cell.transcription_field.input_type == 'spreadsheet' }

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
          page_notes,
          I18n.t("page.edit.page_status_#{page.status}")
        ]

        page_metadata_cells = page_metadata_cells(page)
        data_cells = Array.new(@headings.count, "")
        running_data = []

        if page.sections.blank?
          #get cell data for a page with only one table
          page.table_cells.includes(:transcription_field).group_by(&:row).each do |row, cell_array|
            #get the cell data and add it to the array
            cell_data(cell_array, data_cells)
            if has_spreadsheet
              running_data = process_header_footer_data(data_cells, running_data, cell_array, row)
            end
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
              cell_data(cell_array, data_cells)
              if has_spreadsheet
                running_data = process_header_footer_data(data_cells, running_data, cell_array, row)
              end
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
    if cell.transcription_field_id && cell.transcription_field.present?
      if cell.transcription_field.input_type == 'spreadsheet'
        index = @raw_headings.index(spreadsheet_heading_to_indexable(cell.transcription_field_id, cell.header))
      else
        index = (@raw_headings.index(cell.transcription_field_id))
      end
    end
    index = (@indexable_headings.index(cell.header)) unless index
    index = (@indexable_headings.index(cell.header.downcase)) unless index
    index = (@indexable_headings.index(cell.header.strip.downcase)) unless index

    index
  end


  def cell_data(array, data_cells)
    array.each do |cell|
      index = index_for_cell(cell)
      target = index *2
      data_cells[target] = XmlSourceProcessor.cell_to_plaintext(cell.content)
      data_cells[target+1] = XmlSourceProcessor.cell_to_subject(cell.content)
    end
  end

  def process_header_footer_data(data_cells, running_data, cell_array, rownum)
    # assume that we are a spreadsheet already

    # create running data if it's our first time
    if running_data.nil? 
      running_data = []
    end

    # are we in row 1?  fill the running data with non-spreadsheet fields
    if rownum == 1
      cell_array.each do |cell|
        unless cell.transcription_field.input_type == 'spreadsheet'
          running_data << cell
        end 
      end
    else
      # are we in row 2 or greater?
      # fill data cells from running header/footer data
      cell_data(running_data, data_cells)
    end

    # return the current running data
    running_data
  end



end
