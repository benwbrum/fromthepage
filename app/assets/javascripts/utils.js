;(function($, window, document, undefined) {
  // Global flash messages auto close
  // $('element').flash();
  $.fn.flashclose = function(s) {
    s = $.extend({
      delay_notice: 1000,      // Notice auto close delay, 0 = don't close
      delay_alert: 6000,       // Alert auto close delay
      delay_error: 0,            // Error auto close delay
      delay_info: 30000
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
      if(container.hasClass('flash-info')) {
        delay = s.delay_info;
      }

      // Close on click
      btnclose.one('click', function(e) {
        e.stopPropagation();
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
      selectable: false        // TRUE to change trigger content on select
    }, s || {});

    return this.each(function() {
      var $element = $(this);
      var cfg = $.extend({}, s, $element.data('dropdown'));
      var $trigger = $(cfg.trigger, this);

      // Open/close when clicked on the trigger
      $trigger.on('mousedown.DropDown', function() {
        $element.toggleClass(cfg.openclass);
      });
      //Open on focus
      $trigger.on('focusin.DropDown', function() {
        $element.addClass(cfg.openclass);
      });

      // Close when clicked on an item
      $(cfg.items, this).on('click.DropDown', function() {
        $element.removeClass(cfg.openclass);
        if(cfg.selectable) {
          $trigger.html($(this).html());
        }
      });

      // Close if clicked outside
      $(document).on('click.DropDown', function(e) {
        if($(e.target).closest($element).length === 0) {
          $element.removeClass(cfg.openclass);
        }
      });
      // Close if focus leaves
      $(document).on('focusin.DropDown', function(e) {
        if($(e.target).closest($element).length === 0) {
          $element.removeClass(cfg.openclass);
        }
      });
    });
  };

  // Tooltip with remote content
  // <element data-tooltip='/some/url.html'>
  // $('[data-tooltip]').tooltip();
  $.fn.tooltip = function(s) {
    return this.each(function() {
      var $element = $(this);
      var url = $element.data('tooltip');
      var $tooltip = $('<div>').addClass('tooltip');

      function showTooltip() {
        var offset = $element.offset();
        var pos_top = offset.top + $element.height();
        var pos_left = offset.left;
        $tooltip.css({ 'top': pos_top, 'left': pos_left }).appendTo('body');

        // Load remote content
        if(url) {
          $.ajax({
            url: url,
            cache: false,
            context: this,
            global: false
          }).done(function(data) {
              $tooltip.html(data);
            }).fail(function() {
              $tooltip.html('<small>error :(</small>');
            });
        }
      }

      $element.on('mouseenter', function(e) {
        e.preventDefault();
        showTooltip();

        $tooltip.off('mouseleave');
        $tooltip.on('mouseleave', function(e){
          $(this).remove();
        })
      });

      // Close if clicked outside
      $element.on('mouseleave', function(e) {
        setTimeout(function() {
          if (!$tooltip.is(':hover')) {
            $tooltip.remove();
          }
        }, 100);
      });
    });
  };

  // Manage subject categories with Select2 plugin
  // <select multiple data-assign-categories='/update_subject_category_url'>
  // $('[data-assign-categories]').categoriesSelect();
  $.fn.categoriesSelect = function() {
    return this.each(function() {
      var $element = $(this);
      var update_url = $element.data('assign-categories');
      var collection_slug = $element.data('collection-slug');

      $element.select2({
        placeholder: 'Assign categories...',
        templateResult: function(category) {
          if(!category.id) { return category.text; }
          var level = $(category.element).data('level');
          var $category = $('<div>').css('margin-left', level * 15).text(category.text);
          return $category;
        }
      }).on('select2:select', function(e) {
          $.ajax({
            type: 'POST',
            url: update_url,
            data: { 'status': true, 'category_id': e.params.data.id, 'collection_id': collection_slug }
          });
        }).on('select2:unselect', function(e) {
          $.ajax({
            type: 'POST',
            url: update_url,
            data: { 'status': false, 'category_id': e.params.data.id, 'collection_id': collection_slug }
          });
        });
    });
  };

  $.fn.multiSelect = function() {
    return this.each(function() {
      var $element = $(this);

      $element.select2({
        placeholder: 'Choose...',
        templateResult: function(category) {
          if(!category.id) { return category.text; }
          var level = $(category.element).data('level');
          var $category = $('<div>').css('margin-left', level * 15).text(category.text);
          return $category;
        }
      });
    });
  };

  // Custom input file
  $.fn.inputFile = function() {
    return this.each(function() {
      if(this.inputfile) return;

      var $container = $(this);
      var $button = $('button', $container);
      var $file = $('input[type=file]', $container);
      var $text = $('input[type=text]', $container);

      $button.add($text).on('click', function() {
        $file.click();
      });

      $file.on('change', function() {
        $text.val($file.val());
      });

      this.inputfile = true;
    });
  };

  // Show big image
  $.fn.imageView = function() {
    return this.each(function() {
      var $element = $(this);
      var content = $('<img>').attr('src', $element.attr('href'));
      var litebox = new LiteBox({
        content: content,
        disposable: true,
        cssclass: 'litebox-image'
      });

      $element.on('click', function(e) {
        e.preventDefault();
        litebox.open();
      });
    });
  };

})(jQuery, window, document);
