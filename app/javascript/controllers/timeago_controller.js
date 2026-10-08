import { Controller } from "@hotwired/stimulus"

import "plugins/jquery.timeago";

// Connects to data-controller="timeago"
export default class extends Controller {
  static values = {
    locale: String
  }

  connect() {
    if (this.hasLocaleValue && this.localeValue) {
      $(this.element).timeago("setLocale", this.localeValue)
    }

    $(this.element).timeago()
  }
}
