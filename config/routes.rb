Fromthepage::Application.routes.draw do

  resources :omeka_items


  resources :omeka_sites


  get '/account/login' => 'account#login' # , :as => 'websites'
  post '/account/signin' => 'account#signin'
  post '/account/process_signup' => 'account#process_signup'
  get '/static_splash' => 'static#splash'
  # match '/static/splash' => 'static#splash'

  match '/' => 'static#splash'
  match 'ZenasMatthews' => 'collection#show', :collection_id => 7
  match 'JuliaBrumfield' => 'collection#show', :collection_id => 1
  match '/:controller(/:action(/:id))'

end
