import { Controller } from '@hotwired/stimulus'

// Connects to data-controller='toggle-view'
export default class extends Controller {
  static targets = ['toggleable']

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    const target = event.currentTarget;
    const toggleClass = target.dataset.toggleClass;
    const toggleSelf = target.dataset.toggleSelf === 'true';

    let targets = this.toggleableTargets;

    if (toggleSelf) {
      targets = [target];
    } else if (toggleClass) {
      targets = targets.filter(
        el => el.dataset.toggleClass === toggleClass
      );
    }

    targets.forEach(el => {
      if (toggleClass) {
        el.classList.toggle(toggleClass);
      } else {
        el.style.display = (el.style.display === 'none' || !el.style.display) ? 'block' : 'none'
      }
    });
  }
}
