# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true

# Jquery plugins
pin_all_from 'app/javascript/plugins', under: 'plugins'

pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/actions', under: 'actions'
pin_all_from 'app/javascript/vendor', under: 'vendor'
