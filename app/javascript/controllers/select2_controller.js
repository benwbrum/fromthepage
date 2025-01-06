import { Controller } from "@hotwired/stimulus"

import "select2";

// Connects to data-controller="select2"
export default class extends Controller {

  static values = {
    ajaxUrl: String,
    placeholder: {
      type: String,
      default: "Select..."
    },
  }

  connect() {
    const $element = $(this.element);

    $element.select2(this.options());

    $element.on("select2:select select2:unselect", () => {
      this.syncHiddenField();
    });
  }

  options() {
    const opts = {
      placeholder: this.placeholderValue,
      templateResult: function(option) {
        if(!option.id) { return option.text; }
        var level = $(option.element).data('level');
        var $option = $('<div>').css('margin-left', level * 15).text(option.text);
        return $option;
      },
    }

    if (this.hasAjaxUrlValue) {
      opts.ajax = {
        url: this.ajaxUrlValue,
        dataType: 'json',
        delay: 250,
        data: function (params) {
          var query = { term: params.term }

          return query;
        }
      }
    }

    return opts;
  }

  syncHiddenField() {
    this.element.dispatchEvent(new Event('change', { bubbles: true }));
  }
}
