import { Turbo } from "@hotwired/turbo-rails"

let turboRedirectResponse;
Turbo.StreamActions.redirect = function () {
  const url = this.getAttribute('url');
  turboRedirectResponse = this.getAttribute('response');

  Turbo.visit(url);
};

document.addEventListener('turbo:load', function() {
  if (turboRedirectResponse == null) return;

  Turbo.renderStreamMessage(turboRedirectResponse);
  turboRedirectResponse = null;
});
