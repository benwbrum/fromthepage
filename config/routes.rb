Fromthepage::Application.routes.draw do

  devise_for :users

  resources :omeka_items

  resources :omeka_sites

  resources :notes

  get "/dashboard" => "dashboard#index"

  root :to => 'static#splash'
  get 'ZenasMatthews' => 'collection#show', :collection_id => 7
  get 'JuliaBrumfield' => 'collection#show', :collection_id => 1
  
  patch 'work/update_work', :to => 'work#update_work'

  patch 'transcribe/save_transcription', :to => 'transcribe#save_transcription'
  patch 'transcribe/save_translation', :to => 'transcribe#save_translation'
  patch 'article/update', :to => 'article#update'
  put 'article/article_category', :to => 'article#article_category'
  
  patch 'page_block/update', :to => 'page_block#update'

  
  match '/:controller(/:action(/:id))', via: [:get, :post]

end
