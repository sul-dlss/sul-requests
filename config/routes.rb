Rails.application.routes.draw do
  post "/challenge", to: "bot_challenge_page/bot_challenge_page#verify_challenge", as: :bot_detect_challenge
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

  # Authorization routes
  get 'sso/login', to: 'sessions#login_by_sunetid', as: :login_by_sunetid
  get 'sso/logout', to: 'sessions#destroy', as: :logout

  post '/sessions/login_by_university_id', to: 'sessions#login_by_university_id', as: :login_by_university_id
  post '/sessions/register_visitor', to: 'sessions#register_visitor', as: :register_visitor

  resources :paging_schedule, only: :index
  get 'paging_schedule/from/:origin_library(/to/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/from/:origin_library/to/:destination/:date' => 'paging_schedule#open', as: :open_hours

  match 'reports', to: 'reports#index', via: [:get], as: :reports

  get 'circ-check' => 'circ_check#index', as: :circ_check
  post 'circ-check' => 'circ_check#show', as: :circ_check_item

  get 'reset_pin', to: 'reset_pins#index'
  post 'reset_pin', to: 'reset_pins#reset'
  get 'change_pin', to: 'reset_pins#change_form', as: :change_pin_with_token
  post 'change_pin', to: 'reset_pins#change'

  concern :statusable do
    member do
      get :status, as: :status
    end
  end

  concern :admin_commentable do
    resources :admin_comments
  end

  resources :patron_requests, only: [:new, :show, :create], concerns: [:admin_commentable] do
    resource :needed_date, only: [:edit, :update, :show]
  end

  resources :requests, only: [:new], concerns: [:statusable]
  resources :pages, controller: :requests, only: [], concerns: [:statusable]
  resources :scans, controller: :requests,only: [], concerns: [:statusable]
  resources :mediated_pages, controller: :requests, only: [], concerns: [:statusable]
  resources :hold_recalls, controller: :requests, only: [], concerns: [:statusable]

  resources :aeon_requests, only: [:destroy] do
    collection do
      get :submitted, as: :submitted
      get :drafts, as: :draft
      get :cancelled, as: :cancelled
    end

    member do
      patch :resubmit
    end
  end

  resources :aeon_appointments do
    collection do
      get "available/:reading_room_id/:date", to: 'aeon_appointments#available', as: :available
    end
  end

  resources :admin, only: [:index, :show] do
    member do
      get :holdings, as: :holdings
      get :approve_item, as: :approve_item
      patch :mark_as_done, as: :mark_as_done
      post :comment, as: :comment
    end
  end
  resource :feedback_form, path: 'feedback', only: %I[new create]
  get 'feedback' => 'feedback_forms#new'

  # Archives requests route - handles EAD XML from archives.stanford.edu
  resources :archives_requests, only: [:new, :create]

  Rails.application.routes.draw do
    mount Lookbook::Engine, at: "/lookbook"
  end
end
