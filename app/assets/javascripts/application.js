// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .


;(function($, window, document, undefined) {

// Global flash messages auto close
// $('element').flash();
$.fn.flashclose = function(s) {
  s = $.extend({
    delay_notice: 3000,      // Notice auto close delay, 0 = don't close
    delay_alert: 6000,       // Alert auto close delay
    delay_error: 0           // Error auto close delay
  }, s || {});

  return this.each(function() {
    var container = $(this);
    var btnclose = $('.flash_close', container);
    var delay = s.delay_notice;

    if(container.hasClass('flash-alert')) {
      delay = s.delay_alert;
    }
    if(container.hasClass('flash-error')) {
      delay = s.delay_error;
    }

    // Close on click
    btnclose.one('click', function() {
      container.fadeOut('fast', function() {
        container.remove();
      });
    });

    // Auto close
    if(delay) {
      setTimeout(function() {
        btnclose.trigger('click');
      }, delay);
    }
  });
};


// Custom drop-down open/close toggle
// $('element').dropdown();
// <element data-dropdown='{ "selectable": true, "openclass": "visible"}'>
$.fn.dropdown = function(s) {
  s = $.extend({
    trigger:    'dt',        // A child element which trigger open/close
    items:      'dd > a',    // Clickable elements inside the drop-down
    openclass:  'open',      // CSS class name for the open state
    selectable: false        // TRUE to change trigger text on select
  }, s || {});

  return this.each(function() {
    var $element = $(this);
    var cfg = $.extend({}, s, $element.data('dropdown'));
    var $trigger = $(cfg.trigger, this);

    // Open/close when clicked on the trigger
    $trigger.on('click.DropDown', function() {
      $element.toggleClass(cfg.openclass);
    });

    // Close when clicked on an item
    $(s.items, this).on('click.DropDown', function() {
      $element.removeClass(cfg.openclass);
      if(cfg.selectable) {
        $trigger.text($(this).text());
      }
    });

    // Close if clicked outside
    $(document).on('click.DropDown', function(e) {
      if($(e.target).closest($element).length === 0) {
        $element.removeClass(cfg.openclass);
      }
    });
  });
};

})(jQuery, window, document);


$(function() {
  $('.flash').flashclose();
  $('.dropdown').dropdown();
  $('[data-litebox]').litebox();

  // Global page loading spinner
  $('html').removeClass('page-busy');
  $(window)
    .on('beforeunload', function() { $('html').addClass('page-busy'); })
    .ajaxStart(function() { $('html').addClass('page-busy'); })
    .ajaxComplete(function() { $('html').removeClass('page-busy'); });

  // Show and hide collection statistics
  $('.collection').on('click', '[data-toggle-stats]', function(e) {
    var container = $(e.delegateTarget);
    var stats = $('.collection_stats', container);
    var ishidden = stats.is(':hidden');
    stats[ishidden ? 'slideDown' : 'slideUp']('fast');
    container.toggleClass('stats-visible', ishidden);
  });
});