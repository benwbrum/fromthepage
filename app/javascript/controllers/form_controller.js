import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {

  connect() {
    this.form = this.element;
  }

  requestSubmit(event) {
    event.preventDefault;

    this.form.requestSubmit();
  }
}
