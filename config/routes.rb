Fromthepage::Application.routes.draw do
  root :to => 'static#splash'
  get '/blog' => redirect("https://fromthepage.com/blog/")

  devise_for :users, controllers: { masquerades: "masquerades", registrations: "registrations", omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    get "users/new_trial" => "registrations#new_trial"
    post "registrations/choose_provider", to: 'registrations#choose_saml'
    post "registrations/set_provider", to: 'registrations#set_saml'
    match '/users/auth/saml/:identity_provider_id/callback',
          via: [:get, :post],
          to: 'users/omniauth_callbacks#saml',
          as: 'user_omniauth_callback'

    match '/users/auth/saml/:identity_provider_id',
          via: [:get, :post],
          to: 'users/omniauth_callbacks#passthru',
          as: 'user_omniauth_authorize'
  end

  iiif_for 'riiif/image', at: '/image-service'

  resources :notes

  scope 'admin', as: 'admin' do
    get '/' => 'admin#index'
    get 'collection_list', to: 'admin#collection_list'
    get 'work_list', to: 'admin#work_list'
    get 'owner_list', to: 'admin#owner_list'
    get 'user_list', to: 'admin#user_list'
    get 'flag_list', to: 'admin#flag_list'
    get 'uploads', to: 'admin#uploads'
    get 'tail_logfile', to: 'admin#tail_logfile'
    get 'settings', to: 'admin#settings'
    get 'user_visits', to: 'admin#user_visits'
    get 'edit_user', to: 'admin#edit_user'
    get 'autoflag', to: 'admin#autoflag'
    get 'ok_flag', to: 'admin#ok_flag'
    get 'revert_flag', to: 'admin#revert_flag'
    get 'delete_user', to: 'admin#delete_user'
    get 'view_processing_log', to: 'admin#view_processing_log'
    get 'delete_upload', to: 'admin#delete_upload'
    get 'visit_deeds', to: 'admin#visit_deeds'
    get 'visit_actions', to: 'admin#visit_actions'
    get 'expunge_confirmation', :to => 'admin#expunge_confirmation'
    get 'ok_user', :to => 'admin#ok_user'
    get 'downgrade', to: 'admin#downgrade'
    post 'update', to: 'admin#update'
    patch 'update_user', :to => 'admin#update_user'
    patch 'expunge_user', :to => 'admin#expunge_user'
  end

  scope 'facets', as: 'facets' do
    get 'enable', to: 'facets#enable'
    get 'disable', to: 'facets#disable'
    post 'update', to: 'facets#update'
  end

  scope 'collection', as: 'collection' do
    get 'new', to: 'collection#new'
    get 'delete', to: 'collection#delete'
    get 'activity_download', to: 'collection#activity_download'
    get 'show', to: 'collection#show', as: 'show'
    get 'toggle_collection_active', to: 'collection#toggle_collection_active'
    get 'toggle_collection_api_access', to: 'collection#toggle_collection_api_access'
    get 'contributors_download', to: 'collection#contributors_download'
    get 'enable_fields', to: 'collection#enable_fields'
    get 'enable_document_sets', to: 'collection#enable_document_sets'
    get 'enable_ocr', to: 'collection#enable_ocr'
    get 'disable_ocr', to: 'collection#disable_ocr'
    get 'blank_collection', to: 'collection#blank_collection'
    get 'edit', to: 'collection#edit'
    get 'remove_owner', to: 'collection#remove_owner'
    get 'disable_document_sets', to: 'collection#disable_document_sets'
    get 'disable_fields', to: 'collection#disable_fields'
    get 'publish_collection', to: 'collection#publish_collection'
    get 'remove_collaborator', to: 'collection#remove_collaborator'
    get 'restrict_collection', to: 'collection#restrict_collection'
    get 'restrict_transcreibed', to: 'collection#restrict_transcribed'
    post 'add_collaborator', to: 'collection#add_collaborator'
    post 'add_owner', to: 'collection#add_owner'
    post 'create', to: 'collection#create'
    match 'update/:id', to: 'collection#update', via: [:get, :post], as: 'update'

    scope 'metadata', as: 'metadata' do
      get ':id/example', to: 'metadata#example', as: :example
      get ':id/upload', to: 'metadata#upload', as: :upload
      get 'csv_error', to:'metadata#csv_error'
      post 'create', to: 'metadata#create'
    end

    scope 'editor_button', as: 'editor_button' do
      get ':collection_id/edit', to: 'collection#edit_buttons', as: 'edit'
      post ':collection_id/edit', to: 'collection#update_buttons', as: 'update'
    end
  end



  scope 'work', as: 'work' do
    get 'delete', to: 'work#delete'
    get 'update_featured_page', to: 'work#update_featured_page'
    get 'pages_tab', to: 'work#pages_tab'
    get 'edit', to: 'work#edit'
    get 'revert', to: 'work#revert'
    get 'versions', to: 'work#versions'
    post 'update', to: 'work#update'
    post 'create', to: 'work#create'
    patch 'update_work', :to => 'work#update_work'
  end

  scope 'page', as: 'page' do
    get 'new', to: 'page#new'
    get 'delete', to: 'page#delete'
    get 'reorder_page', to: 'page#reorder_page'
    get 'edit', to: 'page#edit'
    get 'rotate', to: 'page#rotate'
    post 'update', to: 'page#update'
    post 'create', to: 'page#create'
  end

  scope 'article', as: 'article' do
    get 'list', to: 'article#list'
    get 'tooltip', to: 'article#tooltip'
    get 'delete', to: 'article#delete'
    get 'show', to: 'article#show'
    post 'combine_duplicate', to: 'article#combine_duplicate'
    post 'article_category', :to => 'article#article_category'
  end

  scope 'export', as: 'export' do
    get '/', to: 'export#index'
    get 'export_work', to: 'export#export_work'
    get 'export_all_works', to: 'export#export_all_works'
    post ':collection_id/:work_id/printable', to: 'export#printable', as: 'printable'
    get 'show', to: 'export#show'
    get 'tei', to: 'export#tei'
    get 'subject_csv', to: 'export#subject_index_csv'
    get 'subject_details_csv', to: 'export#subject_details_csv'
    get 'table_csv', to: 'export#table_csv'
    get 'export_all_tables', to: 'export#export_all_tables'
    get ':collection_id/work_metadata_csv', to: 'export#work_metadata_csv', as: 'work_metadata'
    get 'edit_contentdm_credentials', to: 'export#edit_contentdm_credentials'
    post 'update_contentdm_credentials', to: 'export#update_contentdm_credentials'
    get 'work_plaintext_verbatim', to: 'export#work_plaintext_verbatim'
  end

  scope 'bulk_export', as: 'bulk_export' do
    get ':collection_id/new', to: 'bulk_export#new', as: 'new'
    post ':collection_id/new', to: 'bulk_export#create', as: 'create'
    get '/', to: 'bulk_export#index', as: 'index'
    get ':bulk_export_id', to: 'bulk_export#show', as: 'show'
    get ':bulk_export_id/download', to: 'bulk_export#download', as: 'download'
  end

  scope 'ia', as: 'ia' do
    get 'import_work', to: 'ia#import_work'
    get 'book_form', to: 'ia#ia_book_form'
    get 'manage', to: 'ia#manage'
    get 'mark_beginning', to: 'ia#mark_beginning'
    get 'mark_end', to: 'ia#mark_end'
    get 'title_from_ocr_top', to: 'ia#title_from_ocr_top'
    get 'title_from_ocr_bottom', to: 'ia#title_from_ocr_bottom'
    post 'convert', to: 'ia#convert'
    post 'import_work', to: 'ia#import_work'
    match 'confirm_import', to: 'ia#confirm_import', via: [:get, :post]
  end

  scope 'dashboard', as: 'dashboard' do
    get '/' => 'dashboard#index'
    get 'owner' => 'dashboard#owner'
    get 'watchlist' => 'dashboard#watchlist'
    get 'startproject', to: 'dashboard#startproject'
    get 'summary', to: 'dashboard#summary'
    get 'collaborator_time_export', to: 'dashboard#collaborator_time_export'
    post 'new_upload', to: 'dashboard#new_upload'
    post 'create_work', to: 'dashboard#create_work'
  end

  scope 'category', as: 'category' do
    get 'edit', to: 'category#edit'
    get 'add_new', to: 'category#add_new'
    get 'enable_gis', to: 'category#enable_gis'
    get 'disable_gis', to: 'category#disable_gis'
    get 'delete', to: 'category#delete'
    post 'create', to: 'category#create'
    patch 'update', :to => 'category#update'
  end

  scope 'transcribe', as: 'transcribe' do
    get 'mark_page_blank', to: 'transcribe#mark_page_blank'
    get 'display_page', to: 'transcribe#display_page'
    get 'assign_categories', to: 'transcribe#assign_categories'
    get 'guest', to: 'transcribe#guest'
    get 'edit_fields', to: 'transcribe#edit_fields'
    get 'translate', to: 'transcribe#translate'
    patch 'save_transcription', :to => 'transcribe#save_transcription'
    patch 'save_translation', :to => 'transcribe#save_translation'
  end

  scope 'deed', as: 'deed' do
    get 'list', to: 'deed#list'
    get 'notes(/:collection_id)', to: 'deed#notes', as: 'notes'
  end

  scope 'static', as: 'static' do
    get 'metadata', to: 'static#metadata'
    get 'faq', to: redirect('/faq', status: 301)
    get 'privacy', to: redirect('/privacy', status: 301)
  end

  scope 'page_version', as: 'page_version' do
    get 'list', to: 'page_version#list'
    get 'show', to: 'page_version#show'
  end

  scope 'article_version', as: 'article_version' do
    get 'list', to: 'article_version#list'
    get 'show', to: 'article_version#show'
  end

  scope 'display', as: 'display' do
    get 'read_work', to: 'display#read_work'
    get 'read_all_works', to: 'display#read_all_works'
    get 'display_page', to: 'display#display_page'
  end

  scope 'user', as: 'user' do
    get 'update_profile', to: 'user#update_profile'
    patch 'update', :to => 'user#update'
    get ':user_id/api_key', to: 'user#api_key', as: 'api_key'
    post ':user_id/api_key', to: 'user#generate_api_key', as: 'generate_api_key'
    post ':user_id/api_key/disable', to: 'user#disable_api_key', as: 'disable_api_key'
    get 'choose_locale/:chosen_locale', to: 'user#choose_locale', as: 'choose_locale'
  end

  scope 'page_block', as: 'page_block' do
    get 'list', to: 'page_block#list'
    patch 'update', :to => 'page_block#update'
    get 'edit', to: 'page_block#edit'
  end

  scope 'rails', as: 'rails' do
    get 'mailers' => "rails/mailers#index"
    get 'mailers/*path' => "rails/mailers#preview"
  end

  scope 'sc_collections', as: 'sc_collections' do
    get 'explore_manifest', to: 'sc_collections#explore_manifest'
    get 'explore_collection', to: 'sc_collections#explore_collection'
    post 'import_cdm', to: 'sc_collections#import_cdm'
    get 'cdm_bulk_import', to: 'sc_collections#cdm_bulk_import_new', as: 'cdm_bulk_import_new'
    post 'cdm_bulk_import', to: 'sc_collections#cdm_bulk_import_create', as: 'cdm_bulk_import_create'
    match 'import', to: 'sc_collections#import', via: [:get, :post]
    match 'convert_manifest', to: 'sc_collections#convert_manifest', via: [:get, :post]
    match 'import_collection', to: 'sc_collections#import_collection', via: [:get, :post]
  end

  scope 'application', as: 'application' do
    post 'guest_transcription', to: 'application#guest_transcription'
  end

  scope 'document_set', as: 'document_set' do
    get 'edit/:id', :to => 'document_sets#edit', as: 'edit'
    get 'remove_from_set', to: 'document_sets#remove_from_set'
    post 'create', :to => 'document_sets#create'
    post 'assign_works', :to => 'document_sets#assign_works'
  end

  scope 'document_sets', as: 'document_sets' do
    get 'restrict_set', to: 'document_sets#restrict_set'
    get 'destroy', to: 'document_sets#destroy'
    get 'publish_set', to: 'document_sets#publish_set'
    get 'remove_set_collaborator', to: 'document_sets#remove_set_collaborator'
    post 'assign_to_set', to: 'document_sets#assign_to_set'
    post 'add_set_collaborator', to: 'document_sets#add_set_collaborator'
  end

  scope 'transcription_field', as: 'transcription_field' do
    patch 'reorder', to: 'transcription_field#reorder_fields'
    get 'delete', to: 'transcription_field#delete'
    get 'edit_fields', to: 'transcription_field#edit_fields'
    get 'line_form', to: 'transcription_field#line_form'
    post 'add_fields', to: 'transcription_field#add_fields'

    scope 'spreadsheet_column', as: 'spreadsheet_column' do
      patch 'reorder', to: 'transcription_field#reorder_columns'
      get 'delete', to: 'transcription_field#delete_column'
      get ':transcription_field_id/edit_columns', to: 'transcription_field#edit_columns'
      get ':transcription_field_id/column_form', to: 'transcription_field#column_form'
      post 'add_columns', to: 'transcription_field#add_columns'
      get ':transcription_field_id/disable_ruler', to: 'transcription_field#disable_ruler', as: 'disable_ruler'
      get ':transcription_field_id/enable_ruler', to: 'transcription_field#enable_ruler', as: 'enable_ruler'
      get ':transcription_field_id/choose_offset', to: 'transcription_field#choose_offset', as: 'choose_offset'
      post ':transcription_field_id/:page_id/save_offset', to: 'transcription_field#save_offset', as: 'save_offset'
    end
  end

  scope 'statistics', as: 'statistics' do
    get 'export_csv', to: 'statistics#export_csv'
  end

  get 'dashboard_role' => 'dashboard#dashboard_role'
  get 'guest_dashboard' => 'dashboard#guest'
  get 'findaproject', to: 'dashboard#landing_page', as: :landing_page
  get 'collections', to: 'dashboard#collections_list', as: :collections_list
  post 'display_search', to: 'display#search'
  get 'paged_search', to: 'display#paged_search'
  get 'demo', to: 'demo#index'

  scope 'feature', as: 'feature' do
    get ':feature/:value', to: 'user#feature_toggle' 
    get ':feature', to: 'user#feature_toggle' 
  end


  namespace :api do
    get '/', to: "api#help"
    namespace :v1 do
      get 'bulk_export', to: 'bulk_export#index'
      get 'bulk_export/:collection_slug', to: 'bulk_export#index'
      post 'bulk_export/:collection_slug', to: 'bulk_export#start'
      get 'bulk_export/:bulk_export_id/status', to: 'bulk_export#status', as: 'bulk_export_status'
      get 'bulk_export/:bulk_export_id/download', to: 'bulk_export#download', as: 'bulk_export_download'
    end
  end


  get '/iiif/:id/manifest', :to => 'iiif#manifest', as: :iiif_manifest
  get '/iiif/:id/layer/:type', :to => 'iiif#layer'
  get '/iiif/collection/:collection_id', :to => 'iiif#collection', as: :iiif_collection
  get '/iiif/set/:document_set_id', :to => 'iiif#document_set', as: :iiif_document_set
  get '/iiif/collections', :to => 'iiif#collections'
  get '/iiif/collections/:user_id', :to => 'iiif#user_collections', as: :iiif_user_collections
  get '/iiif/:page_id/list/:annotation_type', :to => 'iiif#list'
  get '/iiif/:page_id/notes', :to => 'iiif#notes'
  get '/iiif/:page_id/note/:note_id', :to => 'iiif#note'
  get '/iiif/:work_id/canvas/:page_id', :to => 'iiif#canvas'
  get '/iiif/:work_id/status', :to => 'iiif#manifest_status'
  get '/iiif/:work_id/:page_id/status', :to => 'iiif#canvas_status'
  # {scheme}://{host}/{prefix}/{identifier}/annotation/{name}
  get '/iiif/:page_id/annotation/:annotation_type', :to => 'iiif#annotation'
  get '/iiif/:work_id/sequence/:sequence_name', :to => 'iiif#sequence'
  get '/iiif/for/:id', :to => 'iiif#for', :constraints => { :id => /.*/ } # redirector
  get '/iiif/contributions/:domain/:terminus_a_quo/:terminus_ad_quem', constraints: { domain: /.*/ }, :to => 'iiif#contributions'
  get '/iiif/contributions/:domain/:terminus_a_quo', constraints: { domain: /.*/ },:to => 'iiif#contributions'
  get '/iiif/contributions/:domain', constraints: { domain: /.*/ }, :to => 'iiif#contributions'

  get '/iiif/:work_id/export/tei', as: 'iiif_work_export_tei', to: 'iiif#export_work_tei'
  get '/iiif/:work_id/export/html', as: 'iiif_work_export_html', to: 'iiif#export_work_html'
  get '/iiif/:work_id/export/plaintext/searchable', as: 'iiif_work_export_plaintext_searchable', to: 'iiif#export_work_plaintext_searchable'
  get '/iiif/:work_id/export/plaintext/verbatim', as: 'iiif_work_export_plaintext_verbatim', to: 'iiif#export_work_plaintext_verbatim'
  get '/iiif/:work_id/export/plaintext/emended', as: 'iiif_work_export_plaintext_emended', to: 'iiif#export_work_plaintext_emended'
  get '/iiif/:work_id/export/plaintext/translation/verbatim', as: 'iiif_work_export_plaintext_translation_verbatim', to: 'iiif#export_work_plaintext_translation_verbatim'
  get '/iiif/:work_id/export/plaintext/translation/emended', as: 'iiif_work_export_plaintext_translation_emended', to: 'iiif#export_work_plaintext_translation_emended'
  get '/iiif/:work_id/export/:page_id/plaintext/searchable', as: 'iiif_page_export_plaintext_searchable', to: 'iiif#export_page_plaintext_searchable'
  get '/iiif/:work_id/export/:page_id/plaintext/verbatim', as: 'iiif_page_export_plaintext_verbatim', to: 'iiif#export_page_plaintext_verbatim'
  get '/iiif/:work_id/export/:page_id/plaintext/translation/verbatim', as: 'iiif_page_export_plaintext_translation_verbatim', to: 'iiif#export_page_plaintext_translation_verbatim'
  get '/iiif/:work_id/export/:page_id/plaintext/emended', as: 'iiif_page_export_plaintext_emended', to: 'iiif#export_page_plaintext_emended'
  get '/iiif/:work_id/export/:page_id/plaintext/translation/emended', as: 'iiif_page_export_plaintext_translation_emended', to: 'iiif#export_page_plaintext_translation_emended'

  get '/iiif/admin/explore/:at_id', :to => 'sc_collections#explore',:constraints => { :at_id => /.*/ }
  get '/iiif/admin/import_manifest', :to => 'sc_collections#import_manifest'

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
  get   ':collection_id/article/upload', :to => 'article#upload_form', :as => 'article_upload_form'
  post  'article/upload', :to => 'article#subject_upload', :as => 'article_subject_upload'
  get   '/article/upload_example', :to => 'article#upload_example', :as => 'article_upload_example'

  patch 'page_block/update', :to => 'page_block#update'
  patch 'admin/update_user', :to => 'admin#update_user'
  get   'admin/expunge_confirmation', :to => 'admin#expunge_confirmation'
  patch 'admin/expunge_user', :to => 'admin#expunge_user'

  get '/rails/mailers' => "rails/mailers#index"
  get '/rails/mailers/*path' => "rails/mailers#preview"

  get '/software', to: 'static#software', as: :about
  get '/about', to: 'static#about', as: :about_us
  get '/faq', to: 'static#faq', as: :faq
  get '/privacy', to: 'static#privacy', as: :privacy
  post '/contact/send', to: 'contact#send_email', as: 'send_contact_email'
  get '/contact', to: 'contact#form', as: 'contact'
  get '/at', to: 'static#at', as: :at
  get '/AT', to: 'static#at', as: :at_caps
  get '/NatsStory', to: 'static#natsstory', as: :natsstory
  get '/natsstory', to: 'static#natsstory', as: :natsstory_lower
  get '/MeredithsStory', to: 'static#meredithsstory', as: :meredithsstory
  get '/meredithsstory', to: 'static#meredithsstory', as:  :meredithsstory_lower

  resources :document_sets, except: [:show, :create, :edit]

  scope ':user_slug' do
    get 'update_profile', to: 'user#update_profile', as: :update_profile

    resources :collection, path: '', only: [:show] do
      get 'statistics', as: :statistics, to: 'statistics#collection'
      get 'settings', as: :settings, to: 'document_sets#settings'
      get 'subjects', as: :subjects, to: 'article#list'
      get 'export', as: :export, to: 'export#index'
      get 'edit_fields', as: :edit_fields, to: 'transcription_field#edit_fields'
      get 'facets'
      post 'search'

      get 'edit', on: :member
      get 'new_work', on: :member
      get 'collaborators', on: :member, to: 'collection#contributors', as: :contributors
      get 'works_list', as: :works_list, to: 'collection#works_list'
      get 'needs_transcription', as: :needs_transcription, to: 'collection#needs_transcription_pages'
      get 'needs_review', as: :needs_review, to: 'collection#needs_review_pages'
      get 'start_transcribing', as: :start_transcribing, to: 'collection#start_transcribing'

      #work related routes
      #have to use match because it must be both get and post
      match ':work_id', to: 'display#read_work', via: [:get, :post], as: :read_work

      resources :work, path: '', param: :work_id, only: [:edit] do
        get 'download', on: :member
        get 'print', on: :member
        get 'versions', on: :member
        get 'pages', on: :member, as: :pages, to: 'work#pages_tab'
        patch 'update_work', on: :member, as: :update
        post 'add_scribe', on: :member
        get 'remove_scribe', on: :member
      end

      get ':work_id/about', param: :work_id, as: :work_about, to: 'work#show'
      get ':work_id/contents', param: :work_id, as: :work_contents, to: 'display#list_pages'
      get ':work_id/help', param: :work_id, as: :work_help, to: 'static#transcribe_help'
      get ':work_id/export/plaintext/searchable', as: 'work_export_plaintext_searchable', to: 'export#work_plaintext_searchable'
      get ':work_id/export/plaintext/verbatim', as: 'work_export_plaintext_verbatim', to: 'export#work_plaintext_verbatim'
      get ':work_id/export/plaintext/emended', as: 'work_export_plaintext_emended', to: 'export#work_plaintext_emended'
      get ':work_id/export/plaintext/translation/verbatim', as: 'work_export_plaintext_translation_verbatim', to: 'export#work_plaintext_translation_verbatim'
      get ':work_id/export/plaintext/translation/emended', as: 'work_export_plaintext_translation_emended', to: 'export#work_plaintext_translation_emended'

      #page related routes
      get ':work_id/display/:page_id', as: 'display_page', to: 'display#display_page'
      get ':work_id/transcribe/:page_id', as: 'transcribe_page', to: 'transcribe#display_page'
      get ':work_id/guest/:page_id', as: 'guest_page', to: 'transcribe#guest'
      get ':work_id/translate/:page_id', as: 'translate_page', to: 'transcribe#translate'
      get ':work_id/help/:page_id', as: 'help_page', to: 'transcribe#help'
      get ':work_id/still_editing/:page_id', to: 'transcribe#still_editing', as: 'transcribe_still_editing'
      get ':work_id/next_untranscribed_page', as: 'next_untranscribed_page', to: 'transcribe#goto_next_untranscribed_page'

      get ':work_id/edit/:page_id', as: 'edit_page', to: 'page#edit'
      get ':work_id/versions/:page_id', as: 'page_version', to: 'page_version#list'
      get ':work_id/export/:page_id/plaintext/searchable', as: 'page_export_plaintext_searchable', to: 'export#page_plaintext_searchable'
      get ':work_id/export/:page_id/plaintext/verbatim', as: 'page_export_plaintext_verbatim', to: 'export#page_plaintext_verbatim'
      get ':work_id/export/:page_id/plaintext/translation/verbatim', as: 'page_export_plaintext_translation_verbatim', to: 'export#page_plaintext_translation_verbatim'
      get ':work_id/export/:page_id/plaintext/emended', as: 'page_export_plaintext_emended', to: 'export#page_plaintext_emended'
      get ':work_id/export/:page_id/plaintext/translation/emended', as: 'page_export_plaintext_translation_emended', to: 'export#page_plaintext_translation_emended'
      get 'export/version'

      # Page Annotations
      get ':work_id/annotation/:page_id/html/transcription', to: 'annotation#page_transcription_html', as: 'annotation_page_transcription_html'
      get ':work_id/annotation/:page_id/html/translation', to: 'annotation#page_translation_html', as: 'annotation_page_translation_html'

      #article related routes
      match 'article/:article_id', to: 'article#show', via: [:get, :post], as: 'article_show'
      get 'article/:article_id/edit', to: 'article#edit', as: 'article_edit'
      get 'article_version/:article_id', to: 'article_version#list', as: 'article_version'
      patch 'article/update/:article_id', to: 'article#update', as: 'article_update'
    end
  end

  get '/:user_id', to: 'user#profile', as: :user_profile
end
