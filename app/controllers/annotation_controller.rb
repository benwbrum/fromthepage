class AnnotationController < ApplicationController
    include AbstractXmlHelper

    def page_transcription_html
        render_xml_to_html @page.xml_text
    end
    def page_translation_html
        render_xml_to_html @page.xml_translation
    end
    def render_xml_to_html(xml)
        annotation = xml_to_html(xml)
        render  :layout => false, :content_type => "text/html", :plain => annotation
    end
end
