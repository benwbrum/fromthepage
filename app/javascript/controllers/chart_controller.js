import { CHART_TYPES } from "libs/chart/core/foundations/constants";
import useStackedBarRenderer from "libs/chart/mixins/useStackedBarRenderer";

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['canvas'];

  static values = {
    // Supported Variations:
    // `StackedBar`: Refer to 'libs/chart/mixins/useStackedBarRenderer' for payload shape
    type: String,
    payload: Object
  };

  connect() {
    if (this.typeValue === CHART_TYPES.StackedBar) {
      this.renderer = useStackedBarRenderer(this);
    } else {
      console.error('Unsupported chart type');
    }

    this.renderer.render();
  }
}
