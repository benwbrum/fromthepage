import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="subject-heading-status"
// While a subject heading validation runs, refreshes the field row buttons
// so progress and the finished Review Validation button appear without a reload.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.refresh(), this.intervalValue);
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
      if (response.ok) {
        this.element.outerHTML = await response.text();
        return;
      }
    } catch (_error) {
      // Try again on the next interval.
    }
    this.timer = setTimeout(() => this.refresh(), this.intervalValue);
  }
}
