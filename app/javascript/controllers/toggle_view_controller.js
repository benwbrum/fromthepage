import { Controller } from '@hotwired/stimulus'

// Connects to data-controller='toggle-view'
export default class extends Controller {
  static targets = ['toggleable']

  toggle() {
    this.toggleableTargets.forEach(el => {
      el.style.display = (el.style.display === "none" || !el.style.display) ? "block" : "none"
    })
  }
}
