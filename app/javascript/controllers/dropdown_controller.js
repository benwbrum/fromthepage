import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static values = {
    triggerSelector: {
      type: String,
      default: 'dt'
    },
    itemSelector: {
      type: String,
      default: 'dd > a'
    },
    openclass: {
      type: String,
      default: 'open'
    },
    selectable: {
      type: Boolean,
      default: false
    }
  }

  connect() {
    const $element = $(this.element);
    const $trigger = $element.find(this.triggerSelectorValue);

    // Open/close when clicked on the trigger
    $trigger.on('mousedown.DropDown', () => {
      $element.toggleClass(this.openclassValue);
    });

    //Open on focus
    $trigger.on('focusin.DropDown', () => {
      $element.addClass(this.openclassValue);
    });

    // Close when clicked on an item
    $(this.itemSelectorValue, this.element).on('click.DropDown', (event) => {
      $element.removeClass(this.openclassValue);

      if(this.selectableValue) {
        $trigger.html($(event.currentTarget).html());
      }
    });
  }
}
