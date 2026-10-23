import { Controller } from "@hotwired/stimulus"

import "plugins/jquery.litebox";

// Connects to data-controller="litebox"
export default class extends Controller {
  connect() {
    $(this.element).litebox();
  }
}
