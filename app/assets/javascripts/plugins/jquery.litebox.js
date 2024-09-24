/*!
 * jQuery plugin
 * Litebox - modal dialog window
 * Copyright (c) 2015 Nick Seryakov https://github.com/kolking
 *
 * Usage example:
 * new LiteBox({ content: '#MyLiteBox' }).open();
 * new LiteBox({ url: '/contact.html', hash: '#contact' });
 */

;(function($, window, document, undefined) {

  var LiteBox = function(options) {
    this.$win = $(window);
    this.$doc = $(document);
    this.$body = $(document.body);
    this.options = $.extend({}, this.defaults, options);

    if(this.options.hash) {
      if(this.options.hash.toString().charAt(0) !== '#') {
        this.options.hash = '#' + this.options.hash;
      }
      this.$win.on('hashchange.LiteBox', $.proxy(this.checkHash, this));
      this.checkHash();
    }
  };

  LiteBox.prototype = {
    defaults: {
      url: null,              // URL for loading content
      hash: null,             // Hash to show litebox
      content: null,          // Selector for local content element
      cssclass: null,         // Custom CSS class for the litebox
      noscroll: true,         // Disable page scroll when open
      disposable: false,      // Remove from DOM after close
      noclose: false          // Remove close button
    },

    isopen: false,
    $wrapper: null,
    $container: null,
    $content: null,

    checkHash: function() {
      this[this.options.hash.toLowerCase() === window.location.hash.toLowerCase() ? 'open' : 'close']();
    },

    pageScroll: function(enabled) {
      var offset;
      if(enabled) {
        // Enable page scroll
        offset = parseInt($('html').css('top'), 10);
        $('html').css({ 'top':'','width':'','position':'','overflow':'','overflow-y':'' });
        $('html,body').scrollTop(-offset).css('overflow', '');
      } else {
        // Disable page scroll
        if($(document).height() > $(window).height()) {
          offset = $(window).scrollTop();
          $('html').css({
            'top': -offset,
            'width': '100%',
            'position': 'fixed',
            'overflow': 'hidden',
            'overflow-y': 'scroll'
          });
        } else {
          $('html,body').css('overflow', 'hidden');
        }
      }
    },

    open: function() {
      if(this.isopen) return;

      // Disable page scroll
      if(this.options.noscroll) {
        this.pageScroll(false);
      }

      if(this.$wrapper) {
        // Show litebox if already exists
        this.$wrapper.add(this.$container).addClass('visible');
      } else {
        // Create elements
        this.$wrapper = $('<section>').addClass('litebox category_modal').addClass(this.options.cssclass);
        this.$closebutton = $('<a>').addClass('litebox_close')
          .attr('aria-label', 'close').text('×');
        this.$container = $('<div>').addClass('litebox_container');
        this.$content = $('<div>').addClass('litebox_content');

        // Insert into DOM and show
        if(this.options.noclose) {
          this.$container.append(this.$content);
        } else {
          // Bind close handlers
          this.$wrapper.add(this.$closebutton).on('click', $.proxy(this.eventClose, this));
          this.$container.click(function(e) { e.stopPropagation(); });
          this.$container.append(this.$closebutton, this.$content);
        }
        this.$wrapper.append(this.$container).appendTo(this.$body);
        this.$wrapper.css('opacity'); // Force reflow
        this.$wrapper.addClass('visible');

        if(this.options.url) {
          // Load remote content
          this.$wrapper.addClass('litebox-busy');
          $.ajax({
            url: this.options.url,
            cache: false,
            context: this
          }).done(function(data) {
            this.insert(data);
          }).fail(function() {
            this.$wrapper.addClass('litebox-error');
          }).always(function() {
            this.$wrapper.removeClass('litebox-busy');
          });
        } else if(this.options.content) {
          // Get local content
          this.insert($(this.options.content).show());
        } else {
          console.log('LiteBox: No content has been defined');
        }
      }

      // Close with Escape key
      this.$doc.on('keyup.LiteBox', $.proxy(this.eventClose, this));
      this.isopen = true;

      return this;
    },

    insert: function(content) {
      this.$content.html(content);
      this.$container.addClass('visible');
      this.$content.find(':text:not(:hidden,[readonly],[disabled]):first').focus();

      // Close litebox if button[type=reset] pressed
      this.$content.on('click', 'form :reset', $.proxy(this.eventClose, this));

      // Include submit button value into serialization
      this.$content.on('click', 'form :submit', function() {
        var button = $(this);
        button.after($('<input>').attr({
          type: 'hidden',
          name: button.attr('name'),
          value: button.val()
        }));
      });

      // Submit an inner form via ajax
      this.$content.on('submit.LiteBox', 'form', $.proxy(function(e) {
        e.preventDefault();

        var $form = $(e.currentTarget);
        var form_method = $form.attr('method');
        var form_action = $form.attr('action');
        var multipart = $form.attr('enctype') === 'multipart/form-data';
        var form_data = multipart ? new FormData($form[0]) : $form.serialize();
        var $submit = $form.find(':submit').prop('disabled', true);

        this.$content.addClass('ajax-busy');

        $.ajax({
          url: form_action,
          method: form_method,
          data: form_data,
          cache: false,
          context: this,
          contentType: (multipart ? false : 'application/x-www-form-urlencoded; charset=UTF-8'),
          processData: (multipart ? false : true)
        }).done(function(data, textStatus, jqXHR) {
          var status = jqXHR.status;
          var location = jqXHR.getResponseHeader('location');
          if(status === 201) {
            if(location) {
              var oldPath = window.location.href.split('#')[0];
              var newPath = location.split('#')[0];
              window.location.assign(location);

              // Force page reload if location path not changed
              if(newPath === oldPath) {
                window.location.reload();
              }
            } else {
              this.close();
            }
          } else {
            this.$content.html(data);
          }
        }).fail(function() {
          this.$content.addClass('ajax-error');
        }).always(function() {
          $submit.prop('disabled', false);
          this.$content.removeClass('ajax-busy');
        });
      }, this));
    },

    close: function() {
      if(!this.isopen || !this.$wrapper) return;

      // Hide litebox and unbind key handler
      this.$wrapper.removeClass('visible');
      this.$doc.off('keyup.LiteBox');
      this.isopen = false;

      // Enable page scroll
      if(this.options.noscroll) {
        this.pageScroll(true);
      }

      // Remove litebox from DOM after all CSS transitions
      if(this.options.disposable || this.options.url) {
        var events = 'transitionend otransitionend oTransitionEnd webkitTransitionEnd msTransitionEnd';
        this.$wrapper.one(events, $.proxy(this.destroy, this));
      }

      // Make sure to reset location hash
      if(this.options.hash) {
        window.location.replace('#');
      }
    },

    eventClose: function(e) {
      if(e.type === 'keyup' && e.keyCode !== 27) return;

      e.preventDefault();
      e.stopPropagation();

      this.close();
    },

    destroy: function(e) {
      this.$wrapper.remove();
      this.$wrapper = null;
      this.$container = null;
      this.$content = null;
    }
  };

  LiteBox.defaults = LiteBox.prototype.defaults;

  $.fn.litebox = function(eventName) {
    eventName = eventName || 'click';

    return this.each(function() {
      if(!this.litebox) {
        var $elm = $(this);
        var options = $.extend({ url: $elm.attr('href') }, $elm.data('litebox'));
        if(options.hash === true) {
          options.hash = options.url;
        }
        this.litebox = new LiteBox(options);
      }

      $(this).on(eventName, function(e) {
        e.preventDefault();
        if(this.litebox.options.hash) {
          document.location.hash = this.litebox.options.hash;
        } else {
          this.litebox.open();
        }
      });
    });
  };

  window.LiteBox = LiteBox;

})(jQuery, window, document);
