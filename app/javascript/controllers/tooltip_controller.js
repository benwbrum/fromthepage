import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
export default class extends Controller {
  connect() {
    this.$element = $(this.element);
    this.url = this.$element.data('tooltip');
    this.$tooltip = $('<div>').addClass('tooltip');

    this.$element.on('mouseenter', (event) => {
      event.preventDefault();
      this.showTooltip();

      this.$tooltip.off('mouseleave');
      this.$tooltip.on('mouseleave', function(){
        $(this).remove();
      })
    });

    this.$element.on('mouseleave', (event) => {
      setTimeout(() => {
        if (!this.$tooltip.is(':hover')) {
          this.$tooltip.remove();
        }
      }, 100);
    });
  }

  showTooltip() {
    var offset = this.$element.offset();
    var pos_top = offset.top + this.$element.height();
    var pos_left = offset.left;
    this.$tooltip.css({ 'top': pos_top, 'left': pos_left }).appendTo('body');

    if(this.url) {
      $.ajax({
        url: this.url,
        cache: false,
        context: this,
        global: false
      }).done((data) => {
          this.$tooltip.html(data);
        }).fail(() => {
          this.$tooltip.html('<small>error :(</small>');
        });
    }
  }
}
