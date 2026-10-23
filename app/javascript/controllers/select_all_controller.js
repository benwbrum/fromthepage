import { Controller } from "@hotwired/stimulus"

import "plugins/select_all"

// Connects to data-controller="select-all"
export default class extends Controller {
  connect() {
    $(this.element).selectAll();
  }
}
