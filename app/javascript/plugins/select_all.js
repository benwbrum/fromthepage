(function($) {
  $.fn.selectAll = function() {
    return this.each(function() {
      var $selectAllCheckbox = $(this);
      var $classSelector = $selectAllCheckbox.attr('data-select-all');
      var $checkboxes = $(`input:checkbox.${$classSelector}`);

      var allChecked = $checkboxes.length > 0 && $checkboxes.not(':checked').length === 0;
      $selectAllCheckbox.off('change');
      $selectAllCheckbox.prop('checked', allChecked);

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
