import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
export default class extends Controller {
  connect() {
    this.$element = $(this.element);
    this.url = this.$element.data('tooltip');
    this.$tooltip = $('<div>').addClass('tooltip');
    this.timeoutId = null;

    // Mouse events for hover behavior
    this.$element.on('mouseenter', (event) => {
      event.preventDefault();
      this.showTooltip();
    });

    this.$element.on('mouseleave', (event) => {
      this.scheduleHideTooltip();
    });

    // Keyboard events for focus behavior (WCAG 2.1 requirement)
    this.$element.on('focus', (event) => {
      this.showTooltip();
    });

    this.$element.on('blur', (event) => {
      this.scheduleHideTooltip();
    });

    // Click event for accessibility testing and mouse interaction
    this.$element.on('click', (event) => {
      event.preventDefault();
      this.showTooltip();
    });

    // Global escape key handler for dismissal (WCAG 2.1 requirement)
    $(document).on('keydown.tooltip', (event) => {
      if (event.key === 'Escape' && this.$tooltip.is(':visible')) {
        this.hideTooltip();
      }
    });
  }

  disconnect() {
    // Clean up event listeners
    $(document).off('keydown.tooltip');
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }
    this.hideTooltip();
  }

  scheduleHideTooltip() {
    // Clear any existing timeout
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }

    // Schedule hiding with a delay to allow mouse movement to tooltip
    this.timeoutId = setTimeout(() => {
      if (!this.$tooltip.is(':hover') && !this.$element.is(':focus')) {
        this.hideTooltip();
      }
    }, 100);
  }

  hideTooltip() {
    this.$tooltip.remove();
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
      this.timeoutId = null;
    }
  }

  showTooltip() {
    // Clear any scheduled hiding
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
      this.timeoutId = null;
    }

    var offset = this.$element.offset();
    var pos_top = offset.top + this.$element.height();
    var pos_left = offset.left;
    
    // Get the article ID for the tooltip ID from aria-describedby if available
    var tooltipId = this.$element.attr('aria-describedby') || 'tooltip-' + Math.random().toString(36).substr(2, 9);
    
    this.$tooltip.attr('id', tooltipId);
    this.$tooltip.css({ 'top': pos_top, 'left': pos_left }).appendTo('body');

    // Set up tooltip hover behavior to keep it visible (WCAG 2.1 hoverable requirement)
    this.$tooltip.off('mouseenter mouseleave');
    this.$tooltip.on('mouseenter', () => {
      if (this.timeoutId) {
        clearTimeout(this.timeoutId);
        this.timeoutId = null;
      }
    });
    
    this.$tooltip.on('mouseleave', () => {
      this.scheduleHideTooltip();
    });

    if(this.url) {
      $.ajax({
        url: this.url,
        cache: false,
        context: this,
        global: false
      }).done((data) => {
          this.$tooltip.html(data);
          // Add ARIA attributes for accessibility
          this.$tooltip.attr({
            'role': 'tooltip',
            'aria-live': 'polite'
          });
        }).fail(() => {
          this.$tooltip.html('<small>error :(</small>');
          this.$tooltip.attr({
            'role': 'tooltip',
            'aria-live': 'polite'
          });
        });
    }
  }
}
