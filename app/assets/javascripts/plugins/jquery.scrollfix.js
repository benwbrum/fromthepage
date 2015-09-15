/*!
 * jQuery plugin
 * Makes html element fixed when you scroll down
 * Do not use margins for correct width/height calculation
 * Copyright (c) 2014 Nick Seryakov https://github.com/kolking
 *
 * Usage example:
 * $('element').scrollfix({ top: 30, fixedclass: 'fixed' });
 * <element data-scrollfix='{ "top": 30, "fixedclass": "fixed" }'>
 */

;(function($, window, document, undefined) {

  var ScrollFix = function(element, options) {
    this.$win = $(window);
    this.$elm = $(element);
    this.$html = $('html');
    this.options = options;
    this.dataobj = this.$elm.data('scrollfix');
  };

  ScrollFix.prototype = {
    defaults: {
      top: 0,               // Pixel offset from the top when it becomes fixed
      dummy: true,          // Add a dummy element to keep the layout
      width: null,          // If not defined, the width will be calculated
      height: null,         // If not defined, the height will be calculated
      addstyle: true,       // Add fixed position using inline css style
      fixedclass: null      // Classname for the element when it becomes fixed
    },

    // Initial values
    fixed: false,
    $dummy: null,

    init: function() {
      this.cfg = $.extend({}, this.defaults, this.options, this.dataobj);

      // Get width, height and calculate top offset
      this.width = this.cfg.width ? this.cfg.width : this.$elm.width();
      this.height = this.cfg.height ? this.cfg.height : this.$elm.height();
      this.offset = parseInt(this.$elm.offset().top, 10) - this.cfg.top;

      // No need for a dummy if the element position absolute or fixed
      if(this.cfg.dummy && $.inArray(this.$elm.css('position'), ['absolute', 'fixed']) === -1) {
        this.$dummy = $('<div>').css({ 'width': this.width, 'height': this.height });
      }

      // Bind on window scroll event
      this.$win.on('scroll.ScrollFix', $.proxy(this.watch, this)).scroll();

      return this;
    },

    watch: function() {
      // Is it scrolled below the offset?
      var dofix = this.$win.scrollTop() >= this.offset;

      // If the current state changed (we need to fix or unfix)
      // Position check to avoid conflicts with disabled scroll
      if(dofix !== this.fixed && this.$html.css('position') !== 'fixed') {
        this.fixed = dofix;

        // Add or remove css class
        this.$elm.toggleClass(this.cfg.fixedclass, this.cfg.fixedclass && dofix);

        // Add or remove inline style
        if(this.cfg.addstyle) {
          this.$elm.css(
            dofix ?
            { 'position': 'fixed', 'z-index': 9999, 'width': this.width, 'top': this.cfg.top, 'margin-top': 0 } :
            { 'position': '', 'z-index': '', 'width': '', 'top': '', 'margin-top': '' }
          );
        }

        // Add or remove dummy
        if(this.$dummy) {
          if(dofix) {
            this.$dummy.insertBefore(this.$elm);
          } else {
            this.$dummy.remove();
          }
        }
      }
    },
  };

  ScrollFix.defaults = ScrollFix.prototype.defaults;

  $.fn.scrollfix = function(options) {
    return this.each(function() {
      new ScrollFix(this, options).init();
    });
  };

  window.ScrollFix = ScrollFix;

})(jQuery, window, document);