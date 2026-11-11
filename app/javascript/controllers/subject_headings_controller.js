import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="subject-headings"
// Shared behavior for the Validate, Review and Configure Subject Headings modals.
export default class extends Controller {
  static targets = ["file", "submit"]

  // Enable the submit button only once a file has been chosen.
  fileChosen() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !(this.hasFileTarget && this.fileTarget.files.length > 0);
    }
  }

  // Switch to another subject heading modal inside the same LiteBox.
  swap(event) {
    const content = this.element.closest('.litebox_content');
    if (!content) return;

    event.preventDefault();
    $.ajax({ url: event.currentTarget.href, cache: false }).done((html) => {
      $(content).html(html);
      $(content).find(':text:not(:hidden,[readonly],[disabled]):first').focus();
    });
  }

  // Close the LiteBox without saving; outside a LiteBox the link navigates back.
  close(event) {
    const closeButton = this.element.closest('.litebox')?.querySelector('.litebox_close');
    if (!closeButton) return;

    event.preventDefault();
    closeButton.click();
  }
}
