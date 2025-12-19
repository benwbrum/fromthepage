import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-picker"
export default class extends Controller {
  connect() {
    const $container = $(this.element);
    const $button = $container.find('button');
    const $file = $container.find('input[type=file]');
    const $text = $container.find('input[type=text]');

    $button.add($text).on('click', function() {
      $file.click();
    });

    $file.on('change', function() {
      $text.val($file.val());
    });
  }
}
