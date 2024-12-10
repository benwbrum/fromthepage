# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true

# Jquery plugins
pin 'select2', to: '/assets/plugins/select2.js'
pin 'select_all', to: '/assets/plugins/select_all.js'
pin 'litebox', to: '/assets/plugins/jquery.litebox.js'

pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/vendor', under: 'vendor', preload: false
