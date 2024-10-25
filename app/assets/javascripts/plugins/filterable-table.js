/*
 * Author: willnigeldejesus@gmail.com
 * Date:   22th Oct 2024
 */

(function($) {

  $.fn.filterableTable = function(options) {

    const selector = this.attr('data-filterable-table-selector');

    const $form = this;
    const $table = this.find(`#${selector}`);

    $form.on('keydown', 'input', function(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
      }
    });

    $form.on('change', function() {
      $('html').addClass('page-busy');

      const formData = $form.serialize();
      const queryParams = new URLSearchParams(formData).toString();
      const newUrl = `${window.location.pathname}?${queryParams}`;
      history.pushState(null, '', newUrl);

      $.ajax({
        url: $form.attr('action'),
        method: $form.attr('method'),
        data: formData,
        success: function(response) {
          $table.html(response)
          bindSortingClickEvent($table, $form);
          $table.find('.dataTables_empty').attr('colspan', $table.find('th').length);
          $table.find('.dataTables_empty').css('display', '');

          $('html').removeClass('page-busy');
        },
        error: function(jqXHR, textStatus, errorThrown) {
          console.error('Error:', textStatus, errorThrown);

          $('html').removeClass('page-busy');
        }
      });
    });

    bindSortingClickEvent($table, $form);
    $table.find('.dataTables_empty').attr('colspan', $table.find('th').length);
    $table.find('.dataTables_empty').css('display', '');

    function bindSortingClickEvent($table, $form) {
      $table.off('click', '.sorting');
      $table.on('click', '.sorting', function(event) {
        const $sortElement = $(this);
        const sortParam = $sortElement.attr('data-sort');
        const order = $sortElement.hasClass('sorting_asc') ? 'desc' : 'asc';

        $form.find('#sort').val(sortParam);
        $form.find('#order').val(order);

        $form.trigger('change');
      });
    }
  }

})(jQuery);
