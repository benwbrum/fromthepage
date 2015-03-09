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
    delay:      4000         // Auto close delay, 0 = don't close
  }, s || {});

  return this.each(function() {
    var container = $(this);
    var btnclose = $('.flash_close', container);

    // Close on click
    btnclose.one('click', function() {
      container.fadeOut('fast', function() {
        container.remove();
      });
    });

    // Auto close
    if(s.delay) {
      setTimeout(function() {
        btnclose.trigger('click');
      }, s.delay);
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
});