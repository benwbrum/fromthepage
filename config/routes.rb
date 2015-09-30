Fromthepage::Application.routes.draw do

  root :to => 'static#splash'

  devise_for :users
  iiif_for 'riiif/image', at: '/image-service'
  
  get   '/omeka_sites/items' => 'omeka_sites#items'

  resources :omeka_sites
  resources :omeka_items
  resources :sc_canvas
  resources :sc_manifests
  resources :sc_collections

  resources :notes

  get   '/admin' => 'admin#index'

  get   '/dashboard' => 'dashboard#index'
  get   '/dashboard/owner' => 'dashboard#owner'
  get   '/dashboard/staging' => 'dashboard#staging'
  get   '/dashboard/watchlist' => 'dashboard#watchlist'
  
  get   '/iiif/:id/manifest', :to => 'iiif#manifest'

  get   'ZenasMatthews' => 'collection#show', :collection_id => 7
  get   'JuliaBrumfield' => 'collection#show', :collection_id => 1

  patch 'work/update_work', :to => 'work#update_work'
  patch 'transcribe/save_transcription', :to => 'transcribe#save_transcription'
  patch 'transcribe/save_translation', :to => 'transcribe#save_translation'
  patch 'article/update', :to => 'article#update'
  put   'article/article_category', :to => 'article#article_category'
  patch 'category/update', :to => 'category#update'
  patch 'user/update', :to => 'user#update'

  patch 'page_block/update', :to => 'page_block#update'
  patch 'admin/update_user', :to => 'admin#update_user'

  match '/:controller(/:action(/:id))', via: [:get, :post]

end