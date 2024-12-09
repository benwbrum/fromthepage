;(function($, window, document, undefined) {
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
