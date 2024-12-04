;(function($, window, document, undefined) {
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
