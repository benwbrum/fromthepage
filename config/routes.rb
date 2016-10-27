Fromthepage::Application.routes.draw do

  root :to => 'static#splash'

  devise_for :users
  iiif_for 'riiif/image', at: '/image-service'
  
  get   '/omeka_sites/items' => 'omeka_sites#items'

  resources :omeka_sites
  resources :omeka_items
  # resources :sc_canvas
  # resources :sc_manifests
  # resources :sc_collections

  resources :notes

  get   '/admin' => 'admin#index'

  get   '/dashboard' => 'dashboard#index'
  get   '/dashboard/owner' => 'dashboard#owner'
  get   '/dashboard/staging' => 'dashboard#staging'
  get   '/dashboard/watchlist' => 'dashboard#watchlist'
  get   'dashboard_role' => 'dashboard#dashboard_role'
  get   'guest_dashboard' => 'dashboard#guest'
  
  get   '/iiif/:id/manifest', :to => 'iiif#manifest'
  get   '/iiif/:id/layer/:type', :to => 'iiif#layer'
  get   '/iiif/collection/:collection_id', :to => 'iiif#collection'
  get   '/iiif/:page_id/list/:annotation_type', :to => 'iiif#list'
  get   '/iiif/:page_id/notes', :to => 'iiif#notes'  
  get   '/iiif/:page_id/note/:note_id', :to => 'iiif#note'
  get   '/iiif/:work_id/canvas/:page_id', :to => 'iiif#canvas' 
#  {scheme}://{host}/{prefix}/{identifier}/annotation/{name}
  get   '/iiif/:page_id/annotation/:annotation_type', :to => 'iiif#annotation' 
  get   '/iiif/:work_id/sequence/:sequence_name', :to => 'iiif#sequence' 

  get   '/iiif/admin/explore/:at_id', :to => 'sc_collections#explore',:constraints => { :at_id => /.*/ }
 # get   '/iiif/admin/explore_manifest', :to => 'sc_collections#explore_manifest'
  get   '/iiif/admin/import_manifest', :to => 'sc_collections#import_manifest'

  get   'document_set/new', :to => 'document_sets#new'
  get   'document_set/edit/:id', :to => 'document_sets#edit'
  patch   'document_set/update/:id', :to => 'document_sets#update'
  post   'document_set/assign_works', :to => 'document_sets#assign_works'
  get   'document_set/:id', :to => 'document_sets#show'
#  get   'document_set/:document_set_id', :to => 'document_sets#show'
#  resources :document_sets

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
