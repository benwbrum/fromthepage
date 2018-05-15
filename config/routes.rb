Fromthepage::Application.routes.draw do

  root :to => 'static#splash'

  devise_for :users, controllers: { masquerades: "masquerades", registrations: "registrations", omniauth_callbacks: 'users/omniauth_callbacks' }

  iiif_for 'riiif/image', at: '/image-service'
  
  get   '/omeka_sites/items' => 'omeka_sites#items'

  resources :omeka_sites
  resources :omeka_items

  resources :notes

  get   '/admin' => 'admin#index'

  get   '/dashboard' => 'dashboard#index'
  get   '/dashboard/owner' => 'dashboard#owner'
  get   '/dashboard/watchlist' => 'dashboard#watchlist'
  get   'dashboard_role' => 'dashboard#dashboard_role'
  get   'guest_dashboard' => 'dashboard#guest'
  get   'landing_page', to: 'dashboard#landing_page', path: '/findaproject'
  get   'collections_list', to: 'dashboard#collections_list', path: '/collections'
  
  get   '/iiif/:id/manifest', :to => 'iiif#manifest'
  get   '/iiif/:id/layer/:type', :to => 'iiif#layer'
  get   '/iiif/collection/:collection_id', :to => 'iiif#collection'
  get   '/iiif/:page_id/list/:annotation_type', :to => 'iiif#list'
  get   '/iiif/:page_id/notes', :to => 'iiif#notes'  
  get   '/iiif/:page_id/note/:note_id', :to => 'iiif#note'
  get   '/iiif/:work_id/canvas/:page_id', :to => 'iiif#canvas' 
  get   '/iiif/:work_id/status', :to => 'iiif#manifest_status' 
  get   '/iiif/:work_id/:page_id/status', :to => 'iiif#canvas_status' 
#  {scheme}://{host}/{prefix}/{identifier}/annotation/{name}
  get   '/iiif/:page_id/annotation/:annotation_type', :to => 'iiif#annotation' 
  get   '/iiif/:work_id/sequence/:sequence_name', :to => 'iiif#sequence'
  get   '/iiif/for/:id', :to => 'iiif#for', :constraints => { :id => /.*/ } # redirector
  get   '/iiif/contributions/:domain/:terminus_a_quo/:terminus_ad_quem', :to => 'iiif#contributions'
  get   '/iiif/contributions/:domain/:terminus_a_quo', :to => 'iiif#contributions'
  get   '/iiif/contributions/:domain', :to => 'iiif#contributions'

  get   '/iiif/admin/explore/:at_id', :to => 'sc_collections#explore',:constraints => { :at_id => /.*/ }
  get   '/iiif/admin/import_manifest', :to => 'sc_collections#import_manifest'

  get   'ZenasMatthews' => 'collection#show', :collection_id => 7
  get   'JuliaBrumfield' => 'collection#show', :collection_id => 1
  get   'YaquinaLights' => 'collection#show', :collection_id => 58
  
  patch 'work/update_work', :to => 'work#update_work'
  patch 'transcribe/save_transcription', :to => 'transcribe#save_transcription'
  patch 'transcribe/save_translation', :to => 'transcribe#save_translation'
  put   'article/article_category', :to => 'article#article_category'
  patch 'category/update', :to => 'category#update'
  patch 'user/update', :to => 'user#update'

  patch 'page_block/update', :to => 'page_block#update'
  patch 'admin/update_user', :to => 'admin#update_user'

  get '/rails/mailers' => "rails/mailers#index"
  get '/rails/mailers/*path' => "rails/mailers#preview"

  match '/:controller(/:action(/:id))', via: [:get, :post]

  get   'document_set/edit/:id', :to => 'document_sets#edit', as: :edit_document_set
  get 'document_set/remove_from_set', to: 'document_sets#remove_from_set', as: :remove_from_set
  post 'document_set/create', :to => 'document_sets#create', as: :create_document_set
  post   'document_set/assign_works', :to => 'document_sets#assign_works'
  #get 'transcription_field/edit_fields', to: 'transcription_field#edit_fields', as: :edit_fields
  post 'transcription_field/add_fields', to: 'transcription_field#add_fields', as: :add_fields
  get 'transcription_field/line_form', to: 'transcription_field#line_form'

  resources :document_sets, except: [:show, :create, :edit]

  scope ':user_slug' do
    get 'user/update_profile', path: '/update_profile', to: 'user#update_profile', as: :update_profile


    resources :collection, path: '', only: [:show] do
      get 'statistics/collection', path: '/statistics', as: :statistics, to: 'statistics#collection'
      get 'document_sets/settings', path: '/settings', as: :settings, to: 'document_sets#settings'
      get 'article/list/:collection_id', path: '/subjects', as: :subjects, to: 'article#list'
      get 'export/index', path: '/export', as: :export, to: 'export#index'
      get 'transcription_field/edit_fields', path: '/edit_fields', as: :edit_fields, to: 'transcription_field#edit_fields'
      
      get 'edit', on: :member
      get 'new_work', on: :member
      get 'contributors', on: :member, path: '/collaborators'
      get 'works_list', path: 'works_list', as: :works_list, to: 'collection#works_list'
      get 'needs_transcription_pages', path: '/needs_transcription', as: :needs_transcription, to: 'collection#needs_transcription_pages'
      get 'needs_review_pages', path: '/needs_review', as: :needs_review, to: 'collection#needs_review_pages'
      get 'start_transcribing', path: '/start_transcribing', as: :start_transcribing, to: 'collection#start_transcribing'
 
      #work related routes
      #have to use match because it must be both get and post
      match 'display/read_work', path: '/:work_id', as: :read_work, to: 'display#read_work', via: [:get, :post]
      #get 'display/read_all_works', as: :read_all_works, to: 'display#read_all_works'
      resources :work, path: '', param: :work_id, only: [:edit] do
        get 'versions', on: :member
        get 'print', on: :member
        get 'pages_tab', on: :member, as: :pages, path: '/pages'
        patch 'update_work', on: :member, as: :update
        post 'add_scribe', on: :member
        get 'remove_scribe', on: :member
      end
      get 'work/show', path: ':work_id/about', param: :work_id, as: :work_about, to: 'work#show'
      get 'display/list_pages', path: ':work_id/contents', param: :work_id, as: :work_contents, to: 'display#list_pages'
      get 'static/transcribe_help', path: ':work_id/help', param: :work_id, as: :work_help, to: 'static#transcribe_help'
      get 'export/work_plaintext_searchable', path: ':work_id/export/plaintext/searchable', as: 'work_export_plaintext_searchable', to: 'export#work_plaintext_searchable'
      get 'export/work_plaintext_verbatim', path: ':work_id/export/plaintext/verbatim', as: 'work_export_plaintext_verbatim', to: 'export#work_plaintext_verbatim'
      get 'export/work_plaintext_emended', path: ':work_id/export/plaintext/emended', as: 'work_export_plaintext_emended', to: 'export#work_plaintext_emended'
      get 'export/work_plaintext_translation_verbatim', path: ':work_id/export/plaintext/translation/verbatim', as: 'work_export_plaintext_translation_verbatim', to: 'export#work_plaintext_translation_verbatim'
      get 'export/work_plaintext_translation_emended', path: ':work_id/export/plaintext/translation/emended', as: 'work_export_plaintext_translation_emended', to: 'export#work_plaintext_translation_emended'
      
      #page related routes
      get 'display/display_page', path: ':work_id/display/:page_id/', as: 'display_page', to: 'display#display_page'
      get 'transcribe/display_page', path: ':work_id/transcribe/:page_id', as: 'transcribe_page', to: 'transcribe#display_page'
      get 'transcribe/guest', path: ':work_id/guest/:page_id', as: 'guest_page', to: 'transcribe#guest'
      get 'transcribe/translate', path: ':work_id/translate/:page_id', as: 'translate_page', to: 'transcribe#translate'
      get 'transcribe/help', path: ':work_id/help/:page_id', as: 'help_page', to: 'transcribe#help'
      get 'page/edit', path: ':work_id/edit/:page_id', as: 'edit_page', to: 'page#edit'
      get 'page_version/list', path: ':work_id/versions/:page_id', as: 'page_version', to: 'page_version#list'
      get 'export/page_plaintext_searchable', path: ':work_id/export/:page_id/plaintext/searchable', as: 'page_export_plaintext_searchable', to: 'export#page_plaintext_searchable'
      get 'export/page_plaintext_verbatim', path: ':work_id/export/:page_id/plaintext/verbatim', as: 'page_export_plaintext_verbatim', to: 'export#page_plaintext_verbatim'
      get 'export/page_plaintext_translation_verbatim', path: ':work_id/export/:page_id/plaintext/translation/verbatim', as: 'page_export_plaintext_translation_verbatim', to: 'export#page_plaintext_translation_verbatim'
      get 'export/page_plaintext_emended', path: ':work_id/export/:page_id/plaintext/emended', as: 'page_export_plaintext_emended', to: 'export#page_plaintext_emended'
      get 'export/page_plaintext_translation_emended', path: ':work_id/export/:page_id/plaintext/translation/emended', as: 'page_export_plaintext_translation_emended', to: 'export#page_plaintext_translation_emended'

      #article related routes
      match 'article/show', path: '/article/:article_id', to: 'article#show', via: [:get, :post]
      get 'article/edit', path: 'article/:article_id/edit', to: 'article#edit'
      get 'article_version/list', path: 'article_version/:article_id', to: 'article_version#list', as: 'article_version'
      patch 'article/update', path: 'article/update/:article_id', to: 'article#update'

    end
  end

  get '/:user', path: '/:user_id', to: 'user#profile', as: :user_profile

  get 'collection/update/:id', to: 'collection#update', as: :update_collection

  get 'static/faq', to: 'static#faq', as: :faq
  get 'static/about', to: 'static#about', as: :about
  get 'static/privacy', to: 'static#privacy', as: :privacy

end
