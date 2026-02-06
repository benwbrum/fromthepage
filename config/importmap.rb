# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin '@rails/request.js', to: 'requestjs.js'

# CDNs
pin 'chart.js', to: 'https://ga.jspm.io/npm:chart.js@4.4.0/dist/chart.js'
pin '@kurkle/color', to: 'https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js'

# Jquery plugins
pin_all_from 'app/javascript/plugins', under: 'plugins'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/actions', under: 'actions'
pin_all_from 'app/javascript/vendor', under: 'vendor'
pin_all_from 'app/javascript/libs', under: 'libs'
