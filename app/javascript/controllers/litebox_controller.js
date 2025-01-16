import { Controller } from "@hotwired/stimulus"

import "litebox";

// Connects to data-controller="litebox"
export default class extends Controller {
  connect() {
    $(this.element).litebox();
  }
}
