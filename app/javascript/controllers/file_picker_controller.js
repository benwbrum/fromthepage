import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "vendor/activestorage"

// Connects to data-controller="file-picker"
export default class extends Controller {
  static values = {
    directUrl: String,
    directUploadingPlaceholder: String,
    directFailedPlaceholder: String
  }

  connect() {
    this.container = $(this.element);
    this.button = this.container.find('button');
    this.file = this.container.find('input[type=file]');
    this.text = this.container.find('input[type=text]');
    this.hidden = this.container.find('input[type=hidden]');

    this.disabled = false;

    this.button.add(this.text).on('click', () => {
      if(!this.disabled) {
        this.file.click();
      }
    });

    this.file.on('change', (event) => {
      if(this.hasDirectUrlValue) {
        const blobFile = event.target.files[0];
        this.handleDirectUpload(blobFile);
      } else {
        this.text.val(this.file.val());
      }
    });
  }

  handleDirectUpload(blobFile) {
    this.disabled = true;
    this.button.prop('disabled', true);
    this.text.val(this.directUploadingPlaceholderValue);

    new DirectUpload(
      blobFile,
      this.directUrlValue,
      this
    ).create((error, blob) => {
        if (error) {
          this.text.val(this.directFailedPlaceholderValue);
          this.hidden.val('');

          console.error(error);
        } else {
          this.text.val(blob.filename);
          this.hidden.val(blob.signed_id);
        }
      })

    this.disabled = false;
    this.button.prop('disabled', false);
  }
}
