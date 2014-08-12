Fromthepage::Application.routes.draw do

  devise_for :users

  resources :omeka_items

  resources :omeka_sites

  resources :notes

  get "/dashboard" => "dashboard#index"

  root :to => 'static#splash'
  get 'ZenasMatthews' => 'collection#show', :collection_id => 7
  get 'JuliaBrumfield' => 'collection#show', :collection_id => 1
  
  patch 'transcribe/save_transcription', :to => 'transcribe#save_transcription'
  patch 'article/update', :to => 'article#update'
  put 'article/article_category', :to => 'article#article_category'

  
  match '/:controller(/:action(/:id))', via: [:get, :post]

end
