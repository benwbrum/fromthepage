;(function($, window, document, undefined) {
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
