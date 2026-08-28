import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form"
export default class extends Controller {
  connect() {
    this.form = this.element;
  }

  submit(event) {
    event.stopPropagation()
  }

  requestSubmit(event) {
    event.preventDefault();

    this.form.requestSubmit();
  }

  confirmAndSubmit(event) {
    event.preventDefault();
    event.stopPropagation();

    const select = event.target
    const message = select.dataset.confirmMessage || "Are you sure?"

    const previousValue = select.dataset.previousValue

    if (confirm(message)) {
      this.form.requestSubmit()
      select.dataset.previousValue = select.value
    } else {
      select.value = previousValue
    }
  }

  toggleLinkedOption() {
    this.form.querySelectorAll('[data-linked-selector]').forEach((controller) => {
      const enabled = controller.checked
      const selector = controller.dataset.linkedSelector

      this.form.querySelectorAll(selector).forEach((linkedInput) => {
        linkedInput.disabled = !enabled
      })
    })
  }
}
