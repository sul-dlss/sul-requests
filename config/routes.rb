Rails.application.routes.draw do
  resources :messages
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'
  match "/404", to: 'errors#not_found', via: :all
  match "/500", to: 'errors#internal_server_error', via: :all

  require 'sidekiq/web'
  require 'sidekiq_constraint'
  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new

  get 'interstitial' => 'interstitial#show', as: :interstitial

  # Authorization routes
  get 'sso/login', to: 'sessions#login_by_sunetid', as: :login_by_sunetid
  get 'sso/logout', to: 'sessions#destroy', as: :logout

  post '/sessions/login_by_university_id', to: 'sessions#login_by_university_id', as: :login_by_university_id
  post '/sessions/register_visitor', to: 'sessions#register_visitor', as: :register_visitor

  resources :paging_schedule, only: :index
  get 'paging_schedule/:origin(/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/:origin/:destination/:date' => 'paging_schedule#open', as: :open_hours

  get 'circ-check' => 'circ_check#index', as: :circ_check
  post 'circ-check' => 'circ_check#show', as: :circ_check_item

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

  constraints ->(request) { request.params[:step].blank? || request.env['warden'].user.blank? } do
    get '/patron_requests/new', to: 'patron_requests#login'
  end

  resources :patron_requests, only: [:new, :show, :create]

  resources :requests, only: :new
  resources :aeon_pages, only: :new
  resources :pages, concerns: [:admin_commentable, :creatable_via_get_redirect, :successable, :statusable]
  resources :scans, concerns: [:creatable_via_get_redirect, :successable, :statusable]
  resources :mediated_pages, concerns: [:admin_commentable, :creatable_via_get_redirect, :successable, :statusable] do
    resource :needed_date, only: [:edit, :update, :show]
  end
  resources :hold_recalls, concerns: [:creatable_via_get_redirect, :successable, :statusable]

  resources :admin, only: [:index, :show] do
    member do
      get :holdings, as: :holdings
      get :approve_item, as: :approve_item
    end
  end
  resource :feedback_form, path: 'feedback', only: %I[new, create]
  get 'feedback' => 'feedback_forms#new'
end
