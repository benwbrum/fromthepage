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
    delay:      8000         // Auto close delay, 0 = don't close
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

})(jQuery, window, document);


$(function() {
  $('.flash').flashclose();
});