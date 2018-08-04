Fromthepage::Application.routes.draw do

  root :to => 'static#splash'

  devise_for :users, controllers: { masquerades: "masquerades", registrations: "registrations"}



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
  get   '/iiif/for/:id', :to => 'iiif#for', :constraints => { :id => /.*/ }

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

  namespace :api do
    devise_for :user,controllers:{masquerades: "masquerades", registrations: "registrations"}
    devise_scope :user do
      post 'registration' => 'registration#create'

      put 'registration' => 'registration#update'
    end

    post 'users/password' => 'password#create'
    post 'users/password/confirm' => 'password#confirm'

    get 'dashboard' => 'dashboard#index'
    get 'dashboard/guest' => 'dashboard#guest'
    get 'dashboard/owner' => 'dashboard#ownerResponse'
    get 'dashboard/owner/collections' => 'dashboard#collectionsOfOwner'
    get 'dashboard/recent_work' => 'dashboard#recent_work'
    get 'deeds/:id' => 'deed#list'


#    post 'foro', :to=>'foro#create'
#    get 'foro', :to=>'foro#show'
#    put 'foro', :to=>'foro#update'
#    delete 'foro', :to=>'foro#destroy'


    get 'foro/get', :to=>'foro#getByClass'
    resources :foro, path: 'foro', only: [:create, :update, :destroy, :show,]


    get 'publication/lists/', :to=> 'publication#listByPublication'
    post 'publication', :to=>'publication#create'
    get 'publication', :to=>'publication#show'
    put 'publication', :to=>'publication#update'
    delete 'publication', :to=>'publication#destroy'
    get 'publication/list', :to=>'publication#list'


    resources :test, path: 'test', only: [:index]
    post 'login', :to=>'login#login'
    patch '/api/user', :to=>'user#update'
    get 'collection/list_own', :to=>'collection#list_own'

    get 'collection/list', :to=>'collection#collections_list'
    resources :collection, path: 'collection', only: [:create, :update, :destroy, :show] do
      get ':collection_id', path: 'works', as: :works, to: 'collection#show_works'
    end
    resources :work, path: 'work', only: [:create, :update, :destroy, :show] do
      get ':work_id', path: 'pages', as: :pages, to: 'work#show_pages'
    end
    resources :page, path: 'page', only: [:create, :update, :destroy, :show] do
      get '', path: 'marks', as: :show_marks, to: 'mark#list_by_page'
    end
    resources :page, path: 'page-version', only: [:show] do
      get '', path: 'list', as: :list, to: 'page_version#list_by_page'
    end
    resources :mark, path: 'mark', only: [:index, :create, :update, :destroy, :show] do
      get '', path: 'transcriptions', as: :show_transcriptions, to: 'transcription#list_by_mark'
      get '', path: 'votes',  to: 'transcription#list_likes_by_user'

    end
    resources :transcription, path: 'transcription', only: [:index, :create, :update, :destroy, :show] do
      get ':transcription_id', path: 'like', as: :like_transcription, to: 'transcription#like'
      get '', path: 'vote',  to: 'transcription#transcription_like_by_user'
      get ':transcription_id', path: 'dislike', as: :dislike_transcription, to: 'transcription#dislike'
    end
    resources :translation, path: 'translation', only: [:index, :create, :update, :destroy, :show]
    resources :registration, path: 'registration', only: [:create] do
    end
    resources :page, path: 'transcribe', only: [] do
      post ':page_id', path: 'transcribe', as: :save_transcription, to: 'transcribe#save_transcription'
      post ':page_id', path: 'translate', as: :save_translation, to: 'transcribe#save_translation'
    end
    match '/user/badges', as: :user_badges, to: 'badge#list', via: [:get,:post]
    match '/user/metagame/info', as: :user_metagame_info, to: 'user#user_metagame_info', via: [:get,:post]

    resources :user, path: 'user', only: [:create, :update, :destroy, :show] do
    end
    resources :upload, path: 'upload', only: [:create]
  end

  match '/:controller(/:action(/:id))', via: [:get, :post]

  get   'document_set/edit/:id', :to => 'document_sets#edit', as: :edit_document_set
  post 'document_set/create', :to => 'document_sets#create', as: :create_document_set
  post   'document_set/assign_works', :to => 'document_sets#assign_works'

  resources :document_sets, except: [:show, :create, :edit]

  scope ':user_slug' do
    resources :collection, path: '', only: [:show] do
      get 'statistics/collection', path: '/statistics', as: :statistics, to: 'statistics#collection'
      get 'document_sets/settings', path: '/settings', as: :settings, to: 'document_sets#settings'
      get 'article/list/:collection_id', path: '/subjects', as: :subjects, to: 'article#list'
      get 'export/index', path: '/export', as: :export, to: 'export#index'
      get 'edit', on: :member
      get 'new_work', on: :member
      get 'contributors', on: :member, path: '/collaborators'

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

      #page related routes
      get 'display/display_page', path: ':work_id/display/:page_id/', as: 'display_page', to: 'display#display_page'
      get 'transcribe/display_page', path: ':work_id/transcribe/:page_id', as: 'transcribe_page', to: 'transcribe#display_page'
      get 'transcribe/guest', path: ':work_id/guest/:page_id', as: 'guest_page', to: 'transcribe#guest'
      get 'transcribe/translate', path: ':work_id/translate/:page_id', as: 'translate_page', to: 'transcribe#translate'
      get 'page/edit', path: ':work_id/edit/:page_id', as: 'edit_page', to: 'page#edit'
      get 'page_version/list', path: ':work_id/versions/:page_id', as: 'page_version', to: 'page_version#list'

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
