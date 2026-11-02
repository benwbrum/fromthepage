import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "uploadCheck", "checkbox", "savedCheck"]

  connect() {
    this.sync();
  }

  sync() {
    const uploading = !this.hasSavedCheckTarget || this.fileTarget.files.length > 0;
    this.uploadCheckTarget.hidden = !uploading;
    this.checkboxTarget.disabled = !uploading;
    if (this.hasSavedCheckTarget) {
      this.savedCheckTarget.hidden = uploading;
    }
  }
}
