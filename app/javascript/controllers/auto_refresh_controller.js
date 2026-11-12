import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-refresh"
// While background work runs, re-fetches the page every few seconds and swaps in the
// matching element (by the id of this element's parent), so progress updates live.
// The refreshed element only carries this controller while work is still running.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.refresh(), this.intervalValue);
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  async refresh() {
    const container = this.element.parentElement;
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: 'text/html' } });
      if (response.ok && container?.id) {
        const html = new DOMParser().parseFromString(await response.text(), 'text/html');
        const replacement = html.getElementById(container.id);
        if (replacement) {
          container.innerHTML = replacement.innerHTML;
          return;
        }
      }
    } catch (_error) {
      // Try again on the next interval.
    }
    this.timer = setTimeout(() => this.refresh(), this.intervalValue);
  }
}
