module ExportService
  include AbstractXmlHelper

  def add_readme_to_zip(dirname:, out:)
    readme = "#{Rails.root}/doc/zip/README"
    file = File.open(readme, "r")
    path = File.join dirname, 'README.txt'
    out.put_next_entry path
    out.write file.read
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
end
