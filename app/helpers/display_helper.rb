module DisplayHelper
  include AbstractXmlHelper

  # Render a transcription_json hash as the same HTML format produced by
  # TranscriptionField::Lib::Utils.parse_fields — i.e. what the overview tab
  # displays.  Works for both the human page.transcription_json and the AI
  # ai_transcription.transcription_json.
  def ai_field_html(transcription_json, collection)
    return ''.html_safe if transcription_json.blank?

    fields = collection.transcription_fields
                       .includes(:spreadsheet_columns)
                       .order(:line_number, :position)

    html = String.new

    fields.each do |field|
      next if field.input_type == 'instruction'

      value = transcription_json[field.id.to_s]
      separator = field.input_type == 'description' ? ' ' : ': '
      label = "#{ERB::Util.html_escape(field.label)}#{separator}"

      if field.input_type == 'spreadsheet'
        html << "<span class=\"field__label\">#{label}</span>\n"
        if value.is_a?(Array) && value.any?
          cols = field.spreadsheet_columns
          html << '<table class="tabular"><thead><tr>'
          cols.each { |c| html << "<th>#{ERB::Util.html_escape(c.label)}</th>" }
          html << '</tr></thead><tbody>'
          value.each do |row|
            html << '<tr>'
            cols.each do |col|
              cell = row[col.id.to_s]
              html << "<td>#{ERB::Util.html_escape(cell.to_s)}</td>"
            end
            html << '</tr>'
          end
          html << '</tbody></table>'
        end
        html << '<br/><br/>'
      else
        display_value = value.present? ? ERB::Util.html_escape(value.to_s) : ''
        html << "<span class=\"field__label\">#{label}</span>#{display_value}<br/><br/>"
      end
    end

    html.html_safe
  end

  def has_translation?
    @work.supports_translation && !@page.translation_status_new?
  end

  def translation_mode?
    # this expects a page to exist
    if @work.supports_translation
      params[:translation] == 'true'
    else
      false
    end
  end

  def correction_mode?
    @page.work.ocr_correction
  end

  def notes_for(commentable)
    render({ partial: 'note/notes', locals: { commentable: commentable } })
  end

  def page_action(page)
    @path = collection_transcribe_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    if page.status_new?
      if page.work.ocr_correction
        @wording = t('.correct')
      else
        @wording = t('.transcribe')
      end
    elsif page.status_blank?
      @wording = t('.blank_page')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    elsif page.status_needs_review?
      @wording = t('.review')
    elsif page.work.supports_translation?
      @path = collection_translate_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      if page.translation_status_new?
        @wording = t('.translate')
      elsif page.translation_status_needs_review?
        @wording = t('.review')
      elsif page.translation_status_translated?
        unless @collection.subjects_disabled
          @wording = t('.index')
        else
          @wording = t('.completed')
        end
      elsif page.translation_status_indexed?
        @wording = t('.completed')
        @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      end
    elsif page.status_transcribed?
      unless @collection.subjects_disabled
        @wording = t('.index')
      else
        @wording = t('.completed')
      end
    elsif page.status_indexed?
      @wording = t('.completed')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    else
      @wording = t('.incomplete')
    end
  end
end
