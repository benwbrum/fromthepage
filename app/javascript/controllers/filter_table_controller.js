import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter-table"
export default class extends Controller {
  static targets = ['form', 'table', 'sortButton', 'listButton']

  formTargetConnected(target) {
    const $element = $(target);

    $element.on('keydown', 'input', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();

        $element.trigger('change');
      }
    });

    $element.on('change', () => {
      $('html').addClass('page-busy');

      const formData = $element.serialize();
      const queryParams = new URLSearchParams(formData).toString();
      const newUrl = `${window.location.pathname}?${queryParams}`;

      history.pushState(null, '', newUrl);

      fetch(newUrl, {
        method: 'GET',
        headers: { 'Accept': 'text/vnd.turbo-stream.html' }
      })
        .then(response => response.text())
        .then(html => {
          Turbo.renderStreamMessage(html);
          $('html').removeClass('page-busy');
        })
        .catch(error => {
          console.error('Error:', error);
          $('html').removeClass('page-busy');
        });
    });
  }

  formTargetDisconnected(target) {
    const $element = $(target);
    $element.off('keydown');
    $element.off('change');
  }

  sortButtonTargetConnected(target) {
    const $sortElement = $(target);
    const sortParam = $sortElement.attr('data-sort');
    const order = $sortElement.hasClass('sorting_asc') ? 'desc' : 'asc';

    $sortElement.on('click', (event) => {
      $(this.formTarget).find('#sort').val(sortParam);
      $(this.formTarget).find('#order').val(order);

      $(this.formTarget).trigger('change');
    });
  }

  sortButtonTargetDisconnected(target) {
    $(target).off('click');
  }

  listButtonTargetConnected(target) {
    const $listElement = $(target);
    const listParam = $listElement.attr('data-list');
    const listValue = $listElement.attr('data-value');

    $listElement.on('click', (event) => {
      event.preventDefault();
      event.stopPropagation();

      $(this.formTarget).find(`#${listParam}`).val(listValue);

      $(this.listButtonTargets).removeClass('selected');
      $listElement.addClass('selected');

      $(this.formTarget).trigger('change');
    });
  }
}
