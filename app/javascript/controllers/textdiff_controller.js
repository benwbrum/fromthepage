import { Controller } from "@hotwired/stimulus"

import "plugins/textdiff-combined";

// Connects to data-controller="textdiff"
export default class extends Controller {
  connect() {
    let splitter = Object.create(ResizableSplitter);
    splitter.initVertical('#splitter', '#leftColumn', '#rightColumn');

    $('#ai-diff-content').hide();

    this.diffInitialized = false;
  }

  toggle(event) {
    if (event.currentTarget.checked) {
      $('#ai-text-content').hide();
      $('#ai-diff-content').show();

      if (!this.diffInitialized) {
        $('.diff-versions')
          .prettyHTMLDiff({
            changedContainer:  '[data-diff-transcription=changed] div.html-code',
            originalContainer: '[data-diff-transcription=original] div.html-code',
            diffContainer:     '[data-diff-transcription=original] div.html-code'
          });

        this.diffInitialized = true;
      }
    } else {
      $('#ai-text-content').show();
      $('#ai-diff-content').hide();
    }
  }
}
