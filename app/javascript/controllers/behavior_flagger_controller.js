import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import usePasteFlagger from "libs/behavior_flagger/mixins/usePasteFlagger";

// Connects to data-controller="behavior-flagger"
export default class extends Controller {
  static targets = ["editArea"]
  static values = {
    url: String
  }

  initialize() {
    this.disconnectPasteFlagger = usePasteFlagger(this);
  }

  disconnect() {
    this.disconnectPasteFlagger();
  }

  reportBehavior(behavior_type, metadata) {
    const data = JSON.stringify({ suspicious_behavior: { behavior_type, metadata } })

    post(this.urlValue, {
      responseKind: 'json',
      body: data
    });
  }
}
