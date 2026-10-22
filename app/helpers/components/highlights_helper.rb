module Components::HighlightsHelper
  def fe_highlighted_transcription(contents:, term: nil, article_id: nil, classes: nil)
    classes = [classes, 'busy-container'].compact.join(' ')

    render('shared/components/highlighted_transcription', contents: contents, term: term, article_id: article_id, classes: classes)
  end
end
