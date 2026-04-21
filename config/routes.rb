Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'
  post "/feature_flags", to: "sessions#feature_flags", as: :feature_flags
  match "/404", to: 'errors#not_found', via: :all
  match "/500", to: 'errors#internal_server_error', via: :all
  post "/challenge", to: "bot_challenge_page/bot_challenge_page#verify_challenge", as: :bot_detect_challenge

  get 'feedback', to: 'feedback_forms#new', as: :feedback_form
  resource :feedback_form, path: 'feedback', only: %I[create]

  # Authorization routes
  get 'sso/login', to: 'sessions#login_by_sunetid', as: :login_by_sunetid
  get 'sso/logout', to: 'sessions#destroy', as: :logout

  post '/sessions/login_by_university_id', to: 'sessions#login_by_university_id', as: :login_by_university_id
  post '/sessions/register_visitor', to: 'sessions#register_visitor', as: :register_visitor

  get 'circ-check' => 'circ_check#index', as: :circ_check
  post 'circ-check' => 'circ_check#show', as: :circ_check_item

  get 'reset_pin', to: 'reset_pins#index'
  post 'reset_pin', to: 'reset_pins#reset'
  get 'change_pin', to: 'reset_pins#change_form', as: :change_pin_with_token
  post 'change_pin', to: 'reset_pins#change'

  resources :patron_requests, only: [:new, :show, :create] do
    resource :needed_date, only: [:edit, :update, :show]
    resources :admin_comments
  end

  resources :paging_schedule, only: :index
  get 'paging_schedule/from/:origin_library(/to/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/from/:origin_library/to/:destination/:date' => 'paging_schedule#open', as: :open_hours

  # Archives requests route - handles EAD XML from archives.stanford.edu
  get 'archives_requests/new', to: 'patron_requests#new', as: :new_archives_request

  # Legacy route for redirecting old-style requests to the new patron_requests
  resources :requests, only: [:new]

  resources :aeon_requests, only: [:edit, :destroy, :update] do
    collection do
      get :submitted, as: :submitted
      get :drafts, as: :draft
      get :completed, as: :completed
      get :cancelled, as: :cancelled
      delete 'destroy_multiple'
    end

    member do
      patch :resubmit
    end
  end

  resources :aeon_appointments do
    collection do
      get "new/:reading_room_id", to: 'aeon_appointments#new', as: :new_appointment
      get "available/:reading_room_id/:date", to: 'aeon_appointments#available', as: :available
    end

    get :items
  end

  resource :aeon_user, only: [:new, :create] do
    post :terms, to: 'aeon_users#accept_terms', as: :accept_terms
  end

  resources :admin, only: [:index, :show] do
    member do
      get :holdings, as: :holdings
      get :approve_item, as: :approve_item
      patch :mark_as_done, as: :mark_as_done
      post :comment, as: :comment
    end
  end
  resources :messages
  match 'reports', to: 'reports#index', via: [:get], as: :reports

  mount Lookbook::Engine, at: "/lookbook"
  require 'sidekiq/web'
  require 'sidekiq_constraint'
  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new
end
