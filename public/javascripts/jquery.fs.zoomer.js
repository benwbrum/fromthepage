/* 
 * Zoomer v3.0.8 - 2014-03-15 
 * A jQuery plugin for smooth image exploration. Part of the formstone library. 
 * http://formstone.it/components/zoomer/ 
 * 
 * Copyright 2014 Ben Plum; MIT Licensed 
 */ 

;(function ($, window) {
	"use strict";

	var $window = $(window),
		$instances,
		animating = false,
		transformSupported = false;

	/**
	 * @options
	 * @param callback [function] <$.noop> ""
	 * @param controls.postion [string] <"bottom"> "Position of default controls"
	 * @param controls.zoomIn [string] <> "Custom zoom control selecter"
	 * @param controls.zoomOut [string] <> "Custom zoom control selecter"
	 * @param controls.next [string] <> "Custom pagination control selecter"
	 * @param controls.previous [string] <> "Custom pagination control selecter"
	 * @param customClass [string] <''> "Class applied to instance"
	 * @param enertia [number] <0.2> "Zoom smoothing (0.1 = butter, 0.9 = sandpaper)"
	 * @param increment [number] <0.01> "Zoom speed (0.01 = tortoise, 0.1 = hare)"
	 * @param marginMin [] <> ""
	 * @param marginMax [] <> ""
	 * @param retina [boolean] <false> "Flag for retina image support"
	 * @param source [string | object] <null> "Source image (string) or tiles (object)"
	 */
	var options = {
		callback: $.noop,
		controls: {
			position: "bottom",
			zoomIn: null,
			zoomOut: null,
			next: null,
			previous: null
		},
		customClass: "",
		enertia: 0.2,
		increment: 0.01,
		marginMin: 30, // Min bounds
		marginMax: 100, // Max bounds
		retina: false,
		source: null
	};

	// Internal data
	var properties = {
		images: [],
		aspect: "",
		action: "",
		lastAction: "",
		keyDownTime: 0,
		marginReal: 0,
		originalDOM: "",

		// Gallery
		gallery: false,
		index: 0,

		// Tiles
		$tiles: null,
		tiled: false,
		tilesTotal: 0,
		tilesLoaded: 0,
		tiledColumns: 0,
		tiledRows: 0,
		tiledHeight: 0,
		tiledWidth: 0,
		tiledThumbnail: null,

		// Frame
		centerLeft: 0,
		centerTop: 0,
		frameHeight: 0,
		frameWidth: 0,

		// Original image
		naturalHeight: 0,
		naturalWidth: 0,
		imageRatioWide: 0,
		imageRatioTall: 0,

		// Dimensions
		minHeight: null,
		minWidth: null,
		maxHeight: 0,
		maxWidth: 0,

		// Bounds
		boundsTop: 0,
		boundsBottom: 0,
		boundsLeft: 0,
		boundsRight: 0,

		// Image
		imageWidth: 0,
		imageHeight: 0,
		imageLeft: 0,
		imageTop: 0,
		targetImageWidth: 0,
		targetImageHeight: 0,
		targetImageLeft: 0,
		targetImageTop: 0,
		oldImageWidth: 0,
		oldImageHeight: 0,

		// Positioner
		positionerLeft: 0,
		positionerTop: 0,
		targetPositionerLeft: 0,
		targetPositionerTop: 0,

		// Zoom
		zoomPositionLeft: 0,
		zoomPositionTop: 0,

		// Touch Support
		offset: null,
		touches: [],
		zoomPercentage: 1,

		pinchStartX0: 0,
		pinchStartX1: 0,
		pinchStartY0: 0,
		pinchStartY1: 0,

		pinchEndX0: 0,
		pinchEndX1: 0,
		pinchEndY0: 0,
		pinchEndY1: 0,

		lastPinchEndX0: 0,
		lastPinchEndY0: 0,
		lastPinchEndX1: 0,
		lastPinchEndY1: 0,

		pinchDeltaStart: 0,
		pinchDeltaEnd: 0
	};

	/**
	 * @events
	 * @event zoomer.loaded "Source media loaded"
	 */

	var pub = {

		/**
		 * @method
		 * @name defaults
		 * @description Sets default plugin options
		 * @param opts [object] <{}> "Options object"
		 * @example $.zoomer("defaults", opts);
		 */
		defaults: function(opts) {
			options = $.extend(options, opts || {});
			return $(this);
		},

		/**
		 * @method
		 * @name destroy
		 * @description Removes instance of plugin
		 * @example $(".target").zoomer("destroy");
		 */
		destroy: function() {
			var $targets = $(this).each(function(i, target) {
				var data = $(target).data("zoomer");

				if (data) {
					$window.off(".zoomer");
					data.$holder.off(".zoomer");
					data.$zoomer.off(".zoomer");
					data.controls.$zoomIn.off(".zoomer");
					data.controls.$zoomOut.off(".zoomer");
					data.controls.$next.off(".zoomer");
					data.controls.$previous.off(".zoomer");

					data.$target.removeClass("zoomer-element")
								.data("zoomer", null)
								.empty()
								.append(data.originalDOM);
				}
			});

			$instances = $(".zoomer-element");
			if ($instances.length < 1) {
				_clearAnimation();
			}

			return $targets;
		},

		/**
		 * @method
		 * @name load
		 * @description Loads source media
		 * @param source [string | object] "Source image (string) or tiles (object)"
		 * @example $(".target").zoomer("load", "path/to/image.jpg");
		 */
		load: function(source) {
			return $(this).each(function(i, target) {
				var data = $(target).data("zoomer");

				if (data) {
					data.source = source;
					data.index = 0;
					data = _normalizeSource(data);

					_load(data);
				}
			});
		},

		/**
		 * @method
		 * @name pan
		 * @description Pans plugin instances
		 * @param left [int] "Percentage to pan to (50 = half)"
		 * @param top [int] "Percentage to pan to (50 = half)"
		 * @example $(".target").zoomer("pan", 50, 50);
		 */
		pan: function(left, top) {
			return $(this).each(function(i, target) {
				var data = $(target).data("zoomer");

				if (data) {
					left /= 100;
					top /= 100;

					data.targetPositionerLeft = Math.round(data.centerLeft - data.targetImageLeft - (data.targetImageWidth * left));
					data.targetPositionerTop  = Math.round(data.centerTop - data.targetImageTop - (data.targetImageHeight * top));
				}
			});
		},

		/**
		 * @method
		 * @name resize
		 * @description Resizes plugin instange
		 * @example $(".target").zoomer("resize");
		 */
		resize: function() {
			return $(this).each(function(i, target) {
				var data = $(target).data("zoomer");

				if (data) {
					data.frameWidth  = data.$target.outerWidth();
					data.frameHeight = data.$target.outerHeight();
					data.centerLeft  = Math.round(data.frameWidth * 0.5);
					data.centerTop   = Math.round(data.frameHeight * 0.5);

					data = _setMinimums(data);
				}
			});
		},

		/**
		 * @method
		 * @name unload
		 * @description Unload image from plugins instances
		 * @example $(".target").zoomer("unload");
		 */
		unload: function() {
			return $(this).each(function() {
				var data = $(this).data("zoomer");

				if (data && typeof data.$image !== 'undefined') {
					data.$image.remove();
				}
			});
		}
	};

	/**
	 * @method private
	 * @name _init
	 * @description Initializes plugin
	 * @param opts [object] "Initialization options"
	 */
	function _init(opts) {
		// Settings
		opts = $.extend({}, options, properties, opts);

		transformSupported = _getTransformSupport();

		// Apply to each element
		var $items = $(this);
		for (var i = 0, count = $items.length; i < count; i++) {
			_build($items.eq(i), opts);
		}

		// Start main animation loop
		$instances = $(".zoomer-element");
		_startAnimation();

		return $items;
	}

	/**
	 * @method private
	 * @name _build
	 * @description Builds each instance
	 * @param $target [jQuery object] "Target jQuery object"
	 * @param data [object] <{}> "Options object"
	 */
	function _build($target, data) {
		if (!$target.data("zoomer")) {
			data = $.extend({}, data, $target.data("zoomer-options"));

			data.$target = $target;

			data.marginReal = data.marginMin * 2;
			data.originalDOM = data.$target.html();

			if (data.$target.find("img").length > 0) {
				data.source = [];
				data.$target.find("img").each(function() {
					data.source.push($(this).attr("src"));
				});
				data.$target.empty();
			}
			data = _normalizeSource(data);

			// Assemble HTML
			var html = '<div class="zoomer ' + data.customClass + '">';
			html += '<div class="zoomer-positioner">';
			html += '<div class="zoomer-holder">';
			html += '</div>';
			html += '</div>';
			html += '</div>';

			data.$zoomer = $(html);
			data.$target.addClass("zoomer-element")
						.html(data.$zoomer);

			if (data.controls.zoomIn || data.controls.zoomOut || data.controls.next || data.controls.previous) {
				data.controls.$zoomIn = $(data.controls.zoomIn);
				data.controls.$zoomOut = $(data.controls.zoomOut);
				data.controls.$next = $(data.controls.next);
				data.controls.$previous = $(data.controls.previous);
			} else {
				html = '<div class="zoomer-controls zoomer-controls-' + data.controls.position + '">';
				html += '<span class="zoomer-previous">&lsaquo;</span>';
				html += '<span class="zoomer-zoom-out">-</span>';
				html += '<span class="zoomer-zoom-in">+</span>';
				html += '<span class="zoomer-next">&rsaquo;</span>';
				html += '</div>';

				data.$zoomer.append(html);

				data.controls.$default = data.$zoomer.find(".zoomer-controls");
				data.controls.$zoomIn = data.$zoomer.find(".zoomer-zoom-in");
				data.controls.$zoomOut = data.$zoomer.find(".zoomer-zoom-out");
				data.controls.$next = data.$zoomer.find(".zoomer-next");
				data.controls.$previous = data.$zoomer.find(".zoomer-previous");
			}

			// Cache jquery objects
			data.$positioner = data.$zoomer.find(".zoomer-positioner");
			data.$holder = data.$zoomer.find(".zoomer-holder");

			// Bind events
			data.controls.$zoomIn.on("touchstart.zoomer mousedown.zoomer", data, _zoomIn)
								 .on("touchend.zoomer mouseup.zoomer", data, _clearZoom);
			data.controls.$zoomOut.on("touchstart.zoomer mousedown.zoomer", data, _zoomOut)
								  .on("touchend.zoomer mouseup.zoomer", data, _clearZoom);
			data.controls.$next.on("click.zoomer", data, _nextImage);
			data.controls.$previous.on("click.zoomer", data, _previousImage);
			data.$zoomer.on("mousedown.zoomer", data, _dragStart)
						.on("touchstart.zoomer MSPointerDown.zoomer", ":not(.zoomer-controls)", data, _onTouch);

			// Kick it off
			data.$target.data("zoomer", data);
			pub.resize.apply(data.$target);

			if (data.images.length > 0) {
				_load.apply(data.$target, [ data ]);
			}
		}
	}

	/**
	 * @method private
	 * @name _load
	 * @description Delegates loading action
	 * @param data [object] "Instance data"
	 */
	function _load(data) {
		// If gallery
		if (data.gallery) {
			data.$zoomer.addClass("zoomer-gallery");
		} else {
			data.$zoomer.removeClass("zoomer-gallery");
		}

		if (typeof data.$image !== "undefined") {
			data.$holder.animate({ opacity: 0 }, 300, function() {
				pub.unload.apply(data.$target);
				_loadImage.apply(data.$target, [ data, data.images[data.index] ]);
			});
		} else {
			_loadImage.apply(data.$target, [ data, data.images[data.index] ]);
		}
	}

	/**
	 * @method private
	 * @name _loadImage
	 * @description Handles loading an image or set of tiles
	 * @param data [object] "Instance data"
	 * @param source [string | object] "Source URL or object"
	 */
	function _loadImage(data, source) {
		data.loading = true;

		if (data.tiled) {
			data.tilesTotal = 0;
			data.tilesLoaded = 0;
			var html = '<div class="zoomer-tiles">';
			for (var i in data.images[0]) {
				if (data.images[0].hasOwnProperty(i)) {
					for (var j in data.images[0][i]) {
						if (data.images[0][i].hasOwnProperty(j)) {
							html += '<img class="zoomer-image zoomer-tile" src="' + data.images[0][i][j] + '" data-zoomer-tile="' + i + '-' + j + '" />';
							data.tilesTotal++;
						}
					}
				}
			}
			html += '</div>';

			data.$image = $(html);
			data.$tiles = data.$image.find("img");

			data.$tiles.each(function(i, img) {
				var $img = $(img);
				$img.one("load", data, _onTileLoad);

				if ($img[0].complete) {
					$img.trigger("load");
				}
			});
		} else {
			// Cache current image
			data.$image = $('<img class="zoomer-image" />');
			data.$image.one("load.zoomer", data, _onImageLoad)
					   .attr("src", source);

			// If image has already loaded into cache, trigger load event
			if (data.$image[0].complete) {
				data.$image.trigger("load");
			}
		}
	}

	/**
	 * @method private
	 * @name _onTileLoad
	 * @description Handles tile load
	 * @param e [object] "Event data"
	 */
	function _onTileLoad(e) {
		var data = e.data;

		data.tilesLoaded++;
		if (data.tilesLoaded === data.tilesTotal) {
			data.tiledRows = data.images[0].length;
			data.tiledColumns = data.images[0][0].length;

			data.tiledHeight = data.$tiles.eq(0)[0].naturalHeight * data.tiledRows;
			data.tiledWidth = data.$tiles.eq(0)[0].naturalWidth * data.tiledColumns;

			_onImageLoad({ data: data });
		}
	}

	/**
	 * @method private
	 * @name _onImageLoad
	 * @description Handles image load
	 * @param e [object] "Event data"
	 */
	function _onImageLoad(e) {
		var data = e.data;

		if (data.tiled) {
			data.naturalHeight = data.tiledHeight;
			data.naturalWidth  = data.tiledWidth;
		} else {
			data.naturalHeight = data.$image[0].naturalHeight;
			data.naturalWidth  = data.$image[0].naturalWidth;
		}

		if (data.retina) {
			data.naturalHeight /= 2;
			data.naturalWidth /= 2;
		}

		data.$holder.css({
			height: data.naturalHeight,
			width:  data.naturalWidth
		});

		data.targetImageHeight = data.naturalHeight;
		data.targetImageWidth  = data.naturalWidth;

		data.maxHeight = data.naturalHeight;
		data.maxWidth  = data.naturalWidth;

		data.imageRatioWide = data.naturalWidth / data.naturalHeight;
		data.imageRatioTall = data.naturalHeight / data.naturalWidth;

		// Initial sizing to fit screen
		if (data.naturalHeight > (data.frameHeight - data.marginReal) || data.naturalWidth > (data.frameWidth - data.marginReal)) {
			data = _setMinimums(data);
			data.targetImageHeight = data.minHeight;
			data.targetImageWidth  = data.minWidth;
		}

		// SET INITIAL POSITIONS
		data.positionerLeft = data.targetPositionerLeft = data.centerLeft;
		data.positionerTop  = data.targetPositionerTop  = data.centerTop;

		data.imageLeft   = data.targetImageLeft = Math.round(-data.targetImageWidth / 2);
		data.imageTop    = data.targetImageTop  = Math.round(-data.targetImageHeight / 2);
		data.imageHeight = data.targetImageHeight;
		data.imageWidth  = data.targetImageWidth;

		if (transformSupported) {
			var scaleX = data.imageWidth / data.naturalWidth,
				scaleY = data.imageHeight / data.naturalHeight;

			data.$positioner.css( _prefix("transform", "translate3d("+data.positionerLeft+"px, "+data.positionerTop+"px, 0)") );
			data.$holder.css( _prefix("transform", "translate3d(-50%, -50%, 0) scale("+scaleX+","+scaleY+")") );
		} else {
			data.$positioner.css({
				left: data.positionerLeft,
				top:  data.positionerTop
			});
			data.$holder.css({
				left:   data.imageLeft,
				top:    data.imageTop,
				height: data.imageHeight,
				width:  data.imageWidth
			});
		}

		data.$holder.append(data.$image);

		if (data.tiled) {
			data.$holder.css({
				background: "url(" + data.tiledThumbnail + ") no-repeat left top",
				backgroundSize: "100% 100%"
			});

			data.tileHeightPercentage = 100 / data.tiledRows;
			data.tileWidthPercentage  = 100 / data.tiledColumns;

			data.$tiles.css({
				height: data.tileHeightPercentage + "%",
				width:  data.tileWidthPercentage + "%"
			});

			data.$tiles.each(function(i, tile) {
				var $tile = $(tile),
					position = $tile.data("zoomer-tile").split("-");

				$tile.css({
					left: (data.tileWidthPercentage * parseInt(position[1], 10)) + "%",
					top:  (data.tileHeightPercentage * parseInt(position[0], 10)) + "%"
				});
			});
		}

		data.$holder.animate({ opacity: 1 }, 300);
		data.loading = false;

		// Start preloading
		if (data.gallery) {
			_preloadGallery(data);
		}
	}

	/**
	 * @method private
	 * @name _preloadGallery
	 * @description Preloads previous and next images in gallery for faster rendering
	 * @param data [object] "Instance Data"
	 */
	function _preloadGallery(data) {
		if (data.index > 0) {
			$('<img src="' + data.images[data.index - 1] + '">');
		}
		if (data.index < data.images.length - 1) {
			$('<img src="' + data.images[data.index + 1] + '">');
		}
	}

	/**
	 * @method private
	 * @name _setMinimums
	 * @description Sets minimum dimensions
	 * @param data [object] "Instance Data"
	 */
	function _setMinimums(data) {
		if (data.naturalHeight > data.naturalWidth) {
			// Tall
			data.aspect = "tall";

			data.minHeight = Math.round(data.frameHeight - data.marginReal);
			data.minWidth  = Math.round(data.minHeight / data.imageRatioTall);

			if (data.minWidth > (data.frameWidth - data.marginReal)) {
				data.minWidth  = Math.round(data.frameWidth - data.marginReal);
				data.minHeight = Math.round(data.minWidth / data.imageRatioWide);
			}
		} else {
			// Wide
			data.aspect = "wide";

			data.minWidth  = Math.round(data.frameWidth - data.marginReal);
			data.minHeight = Math.round(data.minWidth / data.imageRatioWide);

			if (data.minHeight > (data.frameHeight - data.marginReal)) {
				data.minHeight = Math.round(data.frameHeight - data.marginReal);
				data.minWidth  = Math.round(data.minHeight / data.imageRatioTall);
			}
		}

		return data;
	}

	/**
	 * @method private
	 * @name _render
	 * @description Main animation loop
	 */
	function _render() {
		for (var i = 0, count = $instances.length; i < count; i++) {
			var data = $instances.eq(i).data("zoomer");

			if (typeof data === "object") {
				// Update image and position values
				data = _updateValues(data);
				data.lastAction = data.action;

				// Update DOM
				if (transformSupported) {
					var scaleX = data.imageWidth / data.naturalWidth,
						scaleY = data.imageHeight / data.naturalHeight;

					data.$positioner.css( _prefix("transform", "translate3d("+data.positionerLeft+"px, "+data.positionerTop+"px, 0)") );
					data.$holder.css( _prefix("transform", "translate3d(-50%, -50%, 0) scale("+scaleX+","+scaleY+")") );
				} else {
					data.$positioner.css({
						left: data.positionerLeft,
						top: data.positionerTop
					});
					data.$holder.css({
						left: data.imageLeft,
						top: data.imageTop,
						width: data.imageWidth,
						height: data.imageHeight
					});
				}

				// Run callback function
				if (data.callback) {
					data.callback.apply(data.$zoomer, [
						(data.imageWidth - data.minWidth) / (data.maxWidth - data.minWidth)
					]);
				}
			}
		}
	}

	/**
	 * @method private
	 * @name _updateValues
	 * @description Updates current image values
	 * @param data [object] "Instance Data"
	 */
	function _updateValues(data) {
		// Update values based on current action
		if (data.action === "zoom_in" || data.action === "zoom_out") {
			// Calculate change
			data.keyDownTime += data.increment;
			var delta = ((data.action === "zoom_out") ? -1 : 1) * Math.round((data.imageWidth * data.keyDownTime) - data.imageWidth);

			if (data.aspect === "tall") {
				data.targetImageHeight += delta;
				data.targetImageWidth = Math.round(data.targetImageHeight / data.imageRatioTall);
			} else {
				data.targetImageWidth += delta;
				data.targetImageHeight = Math.round(data.targetImageWidth / data.imageRatioWide);
			}
		}

		// Check Max and Min image values; recenter if too small
		if (data.aspect === "tall") {
			if (data.targetImageHeight < data.minHeight) {
				data.targetImageHeight = data.minHeight;
				data.targetImageWidth  = Math.round(data.targetImageHeight / data.imageRatioTall);
			} else if (data.targetImageHeight > data.maxHeight) {
				data.targetImageHeight = data.maxHeight;
				data.targetImageWidth  = Math.round(data.targetImageHeight / data.imageRatioTall);
			}
		} else {
			if (data.targetImageWidth < data.minWidth) {
				data.targetImageWidth  = data.minWidth;
				data.targetImageHeight = Math.round(data.targetImageWidth / data.imageRatioWide);
			} else if (data.targetImageWidth > data.maxWidth)  {
				data.targetImageWidth  = data.maxWidth;
				data.targetImageHeight = Math.round(data.targetImageWidth / data.imageRatioWide);
			}
		}

		// Calculate new dimensions
		data.targetImageLeft = Math.round(-data.targetImageWidth * 0.5);
		data.targetImageTop  = Math.round(-data.targetImageHeight * 0.5);

		if (data.action === "drag" || data.action === "pinch") {
			data.imageWidth  = data.targetImageWidth;
			data.imageHeight = data.targetImageHeight;
			data.imageLeft   = data.targetImageLeft;
			data.imageTop    = data.targetImageTop;
		} else {
			data.imageWidth  += Math.round((data.targetImageWidth - data.imageWidth) * data.enertia);
			data.imageHeight += Math.round((data.targetImageHeight - data.imageHeight) * data.enertia);
			data.imageLeft   += Math.round((data.targetImageLeft - data.imageLeft) * data.enertia);
			data.imageTop    += Math.round((data.targetImageTop - data.imageTop) * data.enertia);
		}

		// Check bounds of current position and if big enough to drag
		// Set bounds
		data.boundsLeft   = Math.round(data.frameWidth - (data.targetImageWidth * 0.5) - data.marginMax);
		data.boundsRight  = Math.round((data.targetImageWidth * 0.5) + data.marginMax);
		data.boundsTop    = Math.round(data.frameHeight - (data.targetImageHeight * 0.5) - data.marginMax);
		data.boundsBottom = Math.round((data.targetImageHeight * 0.5) + data.marginMax);

		// Check dragging bounds
		if (data.targetPositionerLeft < data.boundsLeft) {
			data.targetPositionerLeft = data.boundsLeft;
		}
		if (data.targetPositionerLeft > data.boundsRight) {
			data.targetPositionerLeft = data.boundsRight;
		}
		if (data.targetPositionerTop < data.boundsTop) {
			data.targetPositionerTop = data.boundsTop;
		}
		if (data.targetPositionerTop > data.boundsBottom) {
			data.targetPositionerTop = data.boundsBottom;
		}

		// Zoom to visible area of image
		if (data.zoomPositionTop > 0 && data.zoomPositionLeft > 0) {
			data.targetPositionerLeft = data.centerLeft - data.targetImageLeft - (data.targetImageWidth * data.zoomPositionLeft);
			data.targetPositionerTop  = data.centerTop - data.targetImageTop - (data.targetImageHeight * data.zoomPositionTop);
		}

		if (data.action !== "pinch") {
			// Recenter when small enough
			if (data.targetImageWidth < data.frameWidth) {
				data.targetPositionerLeft = data.centerLeft;
			}
			if (data.targetImageHeight < data.frameHeight) {
				data.targetPositionerTop = data.centerTop;
			}
		}

		// Calculate new positions
		if (data.action === "drag" || data.action === "pinch") {
			data.positionerLeft = data.targetPositionerLeft;
			data.positionerTop = data.targetPositionerTop;
		} else {
			data.positionerLeft += Math.round((data.targetPositionerLeft - data.positionerLeft) * data.enertia);
			data.positionerTop  += Math.round((data.targetPositionerTop - data.positionerTop) * data.enertia);
		}

		data.oldImageWidth = data.imageWidth;
		data.oldImageHeight = data.imageHeight;

		return data;
	}

	/**
	 * @method private
	 * @name _nextImage
	 * @description Handles next button click
	 * @param e [object] "Event Data"
	 */
	function _nextImage(e) {
		var data = e.data;

		if (!data.loading && data.index+1 < data.images.length) {
			data.index++;
			_load.apply(data.$target, [ data ]);
		}
	}

	/**
	 * @method private
	 * @name _previousImage
	 * @description Handles previous button click
	 * @param e [object] "Event Data"
	 */
	function _previousImage(e) {
		var data = e.data;

		if (!data.loading && data.index-1 >= 0) {
			data.index--;
			_load.apply(data.$target, [ data ]);
		}
	}

	/**
	 * @method private
	 * @name _zoomIn
	 * @description Handles zoom in button click
	 * @param e [object] "Event Data"
	 */
	function _zoomIn(e) {
		e.preventDefault();
		e.stopPropagation();

		var data = e.data;

		data = _setZoomPosition(data);
		data.keyDownTime = 1;
		data.action = "zoom_in";
	}

	/**
	 * @method private
	 * @name _zoomOut
	 * @description Handles zoom out button click
	 * @param e [object] "Event Data"
	 */
	function _zoomOut(e) {
		e.preventDefault();
		e.stopPropagation();

		var data = e.data;

		data = _setZoomPosition(data);
		data.keyDownTime = 1;
		data.action = "zoom_out";
	}

	/**
	 * @method private
	 * @name _clearZoom
	 * @description Clears current zoom action
	 * @param e [object] "Event Data"
	 */
	function _clearZoom(e) {
		e.preventDefault();
		e.stopPropagation();

		var data = e.data;
		data = _clearZoomPosition(data);

		data.keyDownTime = 0;
		data.action = "";
	}

	/**
	 * @method private
	 * @name _setZoomPosition
	 * @description Sets zoom position
	 * @param data [object] "Instance Data"
	 * @param left [number] "Left position"
	 * @param top [number] "Top position"
	 */
	function _setZoomPosition(data, left, top) {
		left = left || (data.imageWidth * 0.5);
		top  = top || (data.imageHeight * 0.5);

		data.zoomPositionLeft = ((left - (data.positionerLeft - data.centerLeft)) / data.imageWidth);
		data.zoomPositionTop  = ((top - (data.positionerTop - data.centerTop)) / data.imageHeight);

		return data;
	}

	/**
	 * @method private
	 * @name _clearZoomPosition
	 * @description Clears zoom position
	 * @param data [object] "Instance Data"
	 */
	function _clearZoomPosition(data) {
		data.zoomPositionTop = 0;
		data.zoomPositionLeft = 0;

		return data;
	}

	/**
	 * @method private
	 * @name _dragStart
	 * @description Handles drag start
	 * @param e [object] "Event Data"
	 */
	function _dragStart(e) {
		if (e.preventDefault) {
			e.preventDefault();
			e.stopPropagation();
		}

		var data = e.data;
		data.action = "drag";

		data.mouseX = e.pageX;
		data.mouseY = e.pageY;

		data.targetPositionerLeft = data.positionerLeft;
		data.targetPositionerTop = data.positionerTop;

		$window.on("mousemove.zoomer", data, _onDrag)
			   .on("mouseup.zoomer", data, _dragStop);
	}

	/**
	 * @method private
	 * @name _onDrag
	 * @description Handles dragging
	 * @param e [object] "Event Data"
	 */
	function _onDrag(e) {
		if (e.preventDefault) {
			e.preventDefault();
			e.stopPropagation();
		}

		var data = e.data;

		if (e.pageX && e.pageY) {
			data.targetPositionerLeft -= Math.round(data.mouseX - e.pageX);
			data.targetPositionerTop  -= Math.round(data.mouseY - e.pageY);

			data.mouseX = e.pageX;
			data.mouseY = e.pageY;
		}
	}

	/**
	 * @method private
	 * @name _dragStop
	 * @description Handles drag end
	 * @param e [object] "Event Data"
	 */
	function _dragStop(e) {
		if (e.preventDefault) {
			e.preventDefault();
			e.stopPropagation();
		}

		var data = e.data;
		data.action = "";

		$window.off("mousemove.zoomer mouseup.zoomer");
	}

	/**
	 * @method private
	 * @name _onTouch
	 * @description Delegates touch event
	 * @param e [object] "Event Data"
	 */
	function _onTouch(e) {
		if ($(e.target).parent(".zoomer-controls").length > 0) {
			return;
		}

		// Stop ms panning and zooming
		if (e.preventManipulation) {
			e.preventManipulation();
		}
		e.preventDefault();
		e.stopPropagation();

		var data = e.data,
			oe = e.originalEvent;

		if (oe.type.match(/(up|end)$/i)) {
			_onTouchEnd(data, oe);
			return;
		}

		if (oe.pointerId) {
			// Normalize MS pointer events back to standard touches
			var activeTouch = false;
			for (var i in data.touches) {
				if (data.touches[i].identifier === oe.pointerId) {
					activeTouch = true;
					data.touches[i].pageX = oe.clientX;
					data.touches[i].pageY = oe.clientY;
				}
			}
			if (!activeTouch) {
				data.touches.push({
					identifier: oe.pointerId,
					pageX: oe.clientX,
					pageY: oe.clientY
				});
			}
		} else {
			// Alias normal touches
			data.touches = oe.touches;
		}

		// Delegate touch actions
		if (oe.type.match(/(down|start)$/i)) {
			_onTouchStart(data);
		} else if (oe.type.match(/move$/i)) {
			_onTouchMove(data);
		}
	}

	/**
	 * @method private
	 * @name _onTouchStart
	 * @description Handles touch start
	 * @param data [object] "Instance Data"
	 */
	function _onTouchStart(data) {
		// Touch events
		if (!data.touchEventsBound) {
			data.touchEventsBound = true;
			$window.on("touchmove.zoomer MSPointerMove.zoomer", data, _onTouch)
				   .on("touchend.zoomer MSPointerUp.zoomer", data, _onTouch);
		}

		data.zoomPercentage = 1;

		if (data.touches.length >= 2) {
			data.offset = data.$zoomer.offset();

			// Double touch - zoom
			data.pinchStartX0 = data.touches[0].pageX - data.offset.left;
			data.pinchStartY0 = data.touches[0].pageY - data.offset.top;
			data.pinchStartX1 = data.touches[1].pageX - data.offset.left;
			data.pinchStartY1 = data.touches[1].pageY - data.offset.top;

			data.pinchStartX = ((data.pinchStartX0 + data.pinchStartX1) / 2.0);
			data.pinchStartY = ((data.pinchStartY0 + data.pinchStartY1) / 2.0);

			data.imageWidthStart = data.imageWidth;
			data.imageHeightStart = data.imageHeight;

			_setZoomPosition(data);

			data.pinchDeltaStart = Math.sqrt(Math.pow((data.pinchStartX1 - data.pinchStartX0), 2) + Math.pow((data.pinchStartY1 - data.pinchStartY0), 2));
		}

		data.mouseX = data.touches[0].pageX;
		data.mouseY = data.touches[0].pageY;
	}

	/**
	 * @method private
	 * @name _onTouchMove
	 * @description Handles touch move
	 * @param data [object] "Instance Data"
	 */
	function _onTouchMove(data) {
		if (data.touches.length === 1) {
			data.action = "drag";

			data.targetPositionerLeft -= (data.mouseX - data.touches[0].pageX);
			data.targetPositionerTop  -= (data.mouseY - data.touches[0].pageY);
		} else if (data.touches.length >= 2) {
			data.action = "pinch";

			data.pinchEndX0 = data.touches[0].pageX - data.offset.left;
			data.pinchEndY0 = data.touches[0].pageY - data.offset.top;
			data.pinchEndX1 = data.touches[1].pageX - data.offset.left;
			data.pinchEndY1 = data.touches[1].pageY - data.offset.top;

			// Double touch - zoom
			// Only if we've actually move our touches
			if (data.pinchEndX0 !== data.lastPinchEndX0 || data.pinchEndY0 !== data.lastPinchEndY0 ||
				data.pinchEndX1 !== data.lastPinchEndX1 || data.pinchEndY1 !== data.lastPinchEndY1) {

				data.pinchDeltaEnd = Math.sqrt(Math.pow((data.pinchEndX1 - data.pinchEndX0), 2) + Math.pow((data.pinchEndY1 - data.pinchEndY0), 2));
				data.zoomPercentage = (data.pinchDeltaEnd / data.pinchDeltaStart);

				data.targetImageWidth  = Math.round(data.imageWidthStart * data.zoomPercentage);
				data.targetImageHeight = Math.round(data.imageHeightStart * data.zoomPercentage);

				data.pinchEndX = ((data.pinchEndX0 + data.pinchEndX1) / 2.0);
				data.pinchEndY = ((data.pinchEndY0 + data.pinchEndY1) / 2.0);

				data.lastPinchEndX0 = data.pinchEndX0;
				data.lastPinchEndY0 = data.pinchEndY0;
				data.lastPinchEndX1 = data.pinchEndX1;
				data.lastPinchEndY1 = data.pinchEndY1;
			}
		}

		data.mouseX = data.touches[0].pageX;
		data.mouseY = data.touches[0].pageY;
    }

   /**
	 * @method private
	 * @name _onTouchEnd
	 * @description Handles touch end
	 * @param data [object] "Instance Data"
	 */
	function _onTouchEnd(data, oe) {
		data.action = "";

		data.lastPinchEndX0 = data.pinchEndX0 = data.pinchStartX0 = 0;
		data.lastPinchEndY0 = data.pinchEndY0 = data.pinchStartY0 = 0;
		data.lastPinchEndX1 = data.pinchEndX1 = data.pinchStartX1 = 0;
		data.lastPinchEndY1 = data.pinchEndY1 = data.pinchStartY1 = 0;

		data.pinchStartX = data.pinchEndX = 0;
		data.pinchStartY = data.pinchEndX = 0;

		_clearZoomPosition(data);

		if (oe.pointerId) {
			for (var i in data.touches) {
				if (data.touches[i].identifier === oe.pointerId) {
					data.touches.splice(i, 1);
				}
			}
		}

		// Clear touch events
		/* if (data.touches.length <= 1) { */
			$window.off(".zoomer");
			data.touchEventsBound = false;
		/*
		} else {
			data.mouseX = data.touches[0].pageX;
			data.mouseY = data.touches[0].pageY;
		}
		*/
	}

	/**
	 * @method private
	 * @name _normalizeSource
	 * @description Normalizes source string or object
	 * @param data [object] "Instance Data"
	 */
	function _normalizeSource(data) {
		data.tiled = false;
		data.gallery = false;

		if (typeof data.source === "string") {
			data.images = [data.source];
		} else {
			if (typeof data.source[0] === "string") {
				data.images = data.source;
				if (data.images.length > 1) {
					data.gallery = true;
				}
			} else {
				data.tiledThumbnail = data.source.thumbnail;
				data.images = [data.source.tiles];
				data.tiled = true;
			}
		}

		return data;
	}

	/**
	 * @method private
	 * @name _startAnimation
	 * @description Starts main animation loop
	 */
	function _startAnimation() {
		if (!animating) {
			animating = true;
			_onAnimate();
		}
	}

	/**
	 * @method private
	 * @name _clearAnimation
	 * @description End main animation loop
	 */
	function _clearAnimation() {
		animating = false;
	}

	/**
	 * @method private
	 * @name _onAnimate
	 * @description Handles RAF
	 */
	function _onAnimate() {
		if (animating) {
			window.requestAnimationFrame(_onAnimate);
			_render();
		}
	}

	/**
	 * @method private
	 * @name _prefix
	 * @description Builds vendor-prefixed styles
	 * @param property [string] "Property to prefix"
	 * @param value [string] "Property value"
	 * @return [string] "Vendor-prefixed style"
	 */
	function _prefix(property, value) {
		var r = {};

		r["-webkit-" + property] = value;
		r[   "-moz-" + property] = value;
		r[    "-ms-" + property] = value;
		r[     "-o-" + property] = value;
		r[             property] = value;

		return r;
	}

	/**
	 * @method private
	 * @name _getTransformSupport
	 * @description Determines if transforms are support
	 * @return [boolean] "True if transforms supported"
	 */
	function _getTransformSupport() {
		var transforms = {
				"webkitTransform": "-webkit-transform",
				"MozTransform":    "-moz-transform",
				"msTransform":     "-ms-transform",
				"OTransform":      "-o-transform",
				"transform":       "transform"
			},
			test = document.createElement("div"),
			has3d;

		document.body.insertBefore(test, null);

		for (var type in transforms) {
			if (test.style[type] !== undefined) {
				test.style[type] = "translate3d(1px, 1px, 1px)";
				has3d = window.getComputedStyle(test).getPropertyValue(transforms[type]);
			}
		}

		document.body.removeChild(test);

		return (has3d !== undefined && has3d.length > 0 && has3d !== "none");
	}

	$.fn.zoomer = function(method) {
		if (pub[method]) {
			return pub[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if (typeof method === 'object' || !method) {
			return _init.apply(this, arguments);
		}
		return this;
	};

	$.zoomer = function(method) {
		if (method === "defaults") {
			pub.defaults.apply(this, Array.prototype.slice.call(arguments, 1));
		}
	};
})(jQuery, window);