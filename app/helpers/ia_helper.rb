module IaHelper



  def display_ocr(ia_leaf)
    raw_text = ia_leaf.ocr_text
    if raw_text.blank?
      ""
    else
      raw(raw_text.gsub('<', '&lt;').gsub('>', '&gt;').gsub("\n\n", '<br /><br />'))
    end
  end


end
