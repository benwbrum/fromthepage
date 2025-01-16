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
    syncOn: {
      // Supported values
      // 1. none - do not trigger
      // 2. commit - on close, we trigger sync
      // 3. default - on select/unselect, we trigger sync
      type: String,
      default: 'default'
    }
  }

  connect() {
    const $element = $(this.element);

    this.isMultiSelect = $element.prop('multiple');
    this.originalValues = this.isMultiSelect
      ? ($element.val() || [])
      : ($element.val() || '');

    $element.select2(this.options());

    if (this.syncOnValue === 'none') {
      return;
    } else if (this.syncOnValue === 'commit') {
      $element.on("select2:close", () => {
        this.syncHiddenField();
      });
    } else {
      $element.on("select2:select select2:unselect", () => {
        this.syncHiddenField();
      });
    }
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
    const $element = $(this.element);

    const currentValues = this.isMultiSelect
      ? ($element.val() || [])
      : ($element.val() || '');

    if (this.areValuesEqual(this.originalValues, currentValues)) {
      return;
    }

    this.originalValues = this.isMultiSelect ? [...currentValues] : currentValues;
    this.element.dispatchEvent(new Event('change', { bubbles: true }));
  }

  areValuesEqual(values1, values2) {
    if (this.isMultiSelect) {
      if (!Array.isArray(values1) || !Array.isArray(values2)) {
        return false;
      }
      if (values1.length !== values2.length) {
        return false;
      }
      return values1.every(value => values2.includes(value)) &&
             values2.every(value => values1.includes(value));
    } else {
      return values1 === values2;
    }
  }

  disconnect() {
    $(this.element).select2("destroy");
  }
}
