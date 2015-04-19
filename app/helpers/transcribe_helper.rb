module TranscribeHelper
  include AbstractXmlHelper
  
  def relevant_transcription_statuses(work)
    statuses = Page::STATUSES
    
    statuses = statuses.invert
    statuses.delete(Page::STATUS_UNCORRECTED_OCR) # never relevant to transcribers in this venue
    statuses.delete(Page::STATUS_INCOMPLETE) if work.ia_work && work.ia_work.use_ocr
    statuses.delete(Page::STATUS_INCOMPLETE_OCR) unless work.ia_work && work.ia_work.use_ocr
    statuses.delete(Page::STATUS_INCOMPLETE_TRANSLATION) #never relevant to transcriptin screen

    statuses.invert
  end
  
  def relevant_translation_statuses(work)
    statuses = Page::STATUSES
    
    statuses.keep_if { |k,v| v == Page::STATUS_INCOMPLETE_TRANSLATION}
    
    statuses
  end
  
  def relevant_status_help(work)
    Page::STATUS_HELP.values.join(" ")
  end
end
