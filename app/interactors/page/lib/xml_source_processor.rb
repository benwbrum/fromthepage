class Page::Lib::XmlSourceProcessor < Xml::Lib::SourceProcessor::Base
  attr_accessor :page

  def initialize(page)
    @page = page
    @collection = @page.collection
  end

  def process
    @page.xml_text = wiki_to_xml(text_type: Page::TEXT_TYPE::TRANSCRIPTION) if @page.source_text_changed?
    @page.xml_translation = wiki_to_xml(text_type: Page::TEXT_TYPE::TRANSLATION) if @page.source_translation_changed?
  end

  private

  def wiki_to_xml(text_type:)
    source_text = text_type == Page::TEXT_TYPE::TRANSCRIPTION ? @page.source_text : @page.source_translation

    xml_string = String.new(source_text)
    xml_string = process_latex_snippets(xml_string)
    xml_string = clean_bad_braces(xml_string)
    xml_string = clean_script_tags(xml_string)
    xml_string = process_square_braces(xml_string) unless @collection.subjects_disabled
    xml_string = process_linewise_markup(xml_string)
    xml_string = process_line_breaks(xml_string)
    xml_string = valid_xml_from_source(xml_string)
    xml_string = update_links_and_xml(xml_string, false, text_type)
    xml_string = postprocess_xml_markup(xml_string)
    postprocess_sections

    xml_string
  end

  LATEX_SNIPPET = /(\{\{tex:?(.*?):?tex\}\})/m
  def process_latex_snippets(text)
    replacements = {}
    figures = @page.tex_figures.to_a

    text.scan(LATEX_SNIPPET).each_with_index do |pair, i|
      with_tags = pair[0]
      contents = pair[1]

      replacements[with_tags] = "<texFigure position=\"#{i + 1}\"/>"

      figure = figures[i] || TexFigure.new
      figure.source = contents unless figure.source == contents
      figures[i] = figure
    end

    @page.tex_figures = figures
    replacements.each_pair do |s, r|
      text.sub!(s, r)
    end

    text
  end
end
