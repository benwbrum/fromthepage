import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    type: String
  }

  connect() {
    this.container = $(this.element);

    let delay;

    if (this.typeValue === 'notice') {
      delay = 1000;
    } else if (this.typeValue === 'alert') {
      delay = 6000;
    } else if (this.typeValue === 'info') {
      delay = 30000;
    } else {
      // Type 'error'
      delay = 0;
    }

    if (delay !== 0) {
      setTimeout(() => {
        this.removeFlashElement();
      }, delay);
    }
  }

  close(event) {
    event.stopPropagation();
    this.removeFlashElement();
  }

  removeFlashElement() {
    this.container.fadeOut('fast', () => {
      this.container.remove();
    });
  }
}
