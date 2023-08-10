Rails.application.routes.draw do
  resources :messages
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'

  require 'sidekiq/web'
  require 'sidekiq_constraint'
  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new

  get 'interstitial' => 'interstitial#show', as: :interstitial

  # Authorization routes
  get 'sso/login' => 'authentication#login', as: :login
  get 'sso/logout' => 'authentication#logout', as: :logout

  resources :paging_schedule, only: :index
  get 'paging_schedule/:origin(/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/:origin/:destination/:date' => 'paging_schedule#open', as: :open_hours

  get '/cdl/checkin' => 'cdl#checkin'
  get '/cdl/checkout' => 'cdl#checkout'
  get '/cdl/renew' => 'cdl#renew'
  get '/cdl/availability/:barcode' => 'cdl#availability', as: :cdl_availability

  concern :creatable_via_get_redirect do
    collection do
      get 'create', as: :create
    end
  end

  concern :successable do
    member do
      get :success, as: :successful
    end
  end

  concern :statusable do
    member do
      get :status, as: :status
    end
  end

  concern :admin_commentable do
    resources :admin_comments
  end

  resources :requests, only: :new
  resources :due_dates, only: :show
  resources :aeon_pages, only: :new
  resources :pages, concerns: [:admin_commentable, :creatable_via_get_redirect, :successable, :statusable]
  resources :scans, concerns: [:creatable_via_get_redirect, :successable, :statusable]
  resources :mediated_pages, concerns: [:admin_commentable, :creatable_via_get_redirect, :successable, :statusable]
  resources :hold_recalls, concerns: [:creatable_via_get_redirect, :successable, :statusable]

  resources :admin, only: [:index, :show] do
    member do
      get :holdings, as: :holdings
      get :approve_item, as: :approve_item
    end
  end
end
