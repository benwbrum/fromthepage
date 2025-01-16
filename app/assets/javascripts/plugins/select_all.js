(function($) {
  $.fn.selectAll = function() {
    return this.each(function() {
      var $selectAllCheckbox = $(this);
      var $classSelector = $selectAllCheckbox.attr('data-select-all');
      var $checkboxes = $(`input:checkbox.${$classSelector}`);

      $selectAllCheckbox.on('change', function() {
        var isChecked = $(this).prop('checked');
        $checkboxes.prop('checked', isChecked);
      });

      $checkboxes.on('click', function() {
        $selectAllCheckbox.prop('checked', false);
      });
    });
  };
})(jQuery);
