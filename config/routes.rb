Fromthepage::Application.routes.draw do

  devise_for :users

  resources :omeka_items

  resources :omeka_sites

  resources :notes

  root :to => 'static#splash'

  get "/admin" => "admin#index"

  get "/dashboard" => "dashboard#index"
  get "/dashboard/owner" => "dashboard#owner"
  get "/dashboard/staging" => "dashboard#staging"
  get "/dashboard/watchlist" => "dashboard#watchlist"

  get 'ZenasMatthews' => 'collection#show', :collection_id => 7
  get 'JuliaBrumfield' => 'collection#show', :collection_id => 1

  patch 'work/update_work', :to => 'work#update_work'

  patch 'transcribe/save_transcription', :to => 'transcribe#save_transcription'
  patch 'transcribe/save_translation', :to => 'transcribe#save_translation'
  patch 'article/update', :to => 'article#update'
  put 'article/article_category', :to => 'article#article_category'

  patch 'page_block/update', :to => 'page_block#update'
  patch 'admin/update_user', :to => 'admin#update_user'

  match '/:controller(/:action(/:id))', via: [:get, :post]

end
