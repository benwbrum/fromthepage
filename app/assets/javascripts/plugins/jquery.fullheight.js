/*!
 * jQuery plugin
 * Set html element height dinamically based on viewport height
 *
 * Usage example:
 * $('element').fullheight({ bottom: 30, cssrule: 'height' });
 * <element data-fullheight='{ "bottom": 30, "cssrule": "height" }'>
 */

;(function($, window, document, undefined) {

	var FullHeight = function(element, options) {
		this.$win = $(window);
		this.$elm = $(element);
		this.options = options;
		this.dataobj = this.$elm.data('fullheight');
	};

	FullHeight.prototype = {
		defaults: {
			bottom: 0,								// Offset at the bottom of the page
			cssrule: 'min-height'			// CSS rule for setting the height
		},

		init: function() {
			this.cfg = $.extend({}, this.defaults, this.options, this.dataobj);

			// Fallback to default 'cssrule' value
			if($.inArray(this.cfg.cssrule, ['min-height', 'height', 'max-height']) === -1) {
				this.cfg.cssrule = this.defaults.cssrule;
			}

			// Bind on window resize event
			this.$win.on('resize.FullHeight', $.proxy(this.watch, this)).resize();

			return this;
		},

		watch: function() {
			// Calculate the offset from the bottom
			var offset = this.$elm.offset().top + this.cfg.bottom;

			// Set the height
			this.$elm.css(this.cfg.cssrule, this.$win.height() - offset);
		},
	};

	FullHeight.defaults = FullHeight.prototype.defaults;

	$.fn.fullheight = function(options) {
		return this.each(function() {
			new FullHeight(this, options).init();
		});
	};

	window.FullHeight = FullHeight;

})(jQuery, window, document);