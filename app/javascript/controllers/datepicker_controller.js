import { Controller } from "@hotwired/stimulus"

import datePickerController from "plugins/datepicker.min";

// Connects to data-controller="datepicker"
export default class extends Controller {
  static values = {
    dateFormat: {
      type: String,
      default: "%M %d, %Y"
    },
    noFadeEffect: {
      type: Boolean,
      default: true
    },
    rangeHighOffset: {
      type: Number,
      default: -1 // Yesterday
    }
  }

  connect() {
    const rangeHigh = new Date();
    rangeHigh.setDate(rangeHigh.getDate() + this.rangeHighOffsetValue);

    const fieldName = this.element.id;

    this.datePicker = datePickerController.createDatePicker({
      formElements: {
        [fieldName]: this.dateFormatValue
      },
      noFadeEffect: this.noFadeEffectValue,
      rangeHigh: rangeHigh
    });
  }
}
