module ExportService
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
end
