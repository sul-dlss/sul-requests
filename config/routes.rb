Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'
  get 'home/folio', to: 'home#show_folio', as: :folio_dashboard
  get 'home/aeon', to: 'home#show_aeon', as: :aeon_dashboard

  get "/feature_flags", to: "feature_flags#index", as: :feature_flags
  post "/feature_flags", to: "feature_flags#update"
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
  post '/sessions/proxy', to: 'sessions#proxy', as: :proxy

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
  resource :item_selector, only: :show

  resources :paging_schedule, only: :index
  get 'paging_schedule/from/:origin_library(/to/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/from/:origin_library/to/:destination/:date' => 'paging_schedule#open', as: :open_hours

  get '/library_hours/:library_slug/location/:location_slug/closures', to: 'library_hours#closures', as: :closures

  # Archives requests route - handles EAD XML from archives.stanford.edu
  get 'archives_requests/new', to: 'patron_requests#new', as: :new_archives_request


  resources :checkouts, only: [:index] do
    post 'renew', on: :member
    post 'renew_eligible', on: :collection
  end
  resources :fines, only: [:index]
  resources :payments, only: [:index, :create]
  post '/payments/accept', to: 'payments#accept'
  post '/payments/cancel', to: 'payments#cancel'

  # requests#new is a legacy route for redirecting old-style requests to the new patron_requests
  get 'requests/new', to: 'requests#new', as: :new_request
  get 'requests/unified', to: 'requests#index', as: :unified_requests
  get 'requests/mediated', to: 'mediated_requests#index', as: :mediated_requests
  resources :folio_requests, except: [:new, :create], path: 'requests'
  resources :ill_requests, only: [:index, :new, :create, :destroy]

  resources :aeon_requests, only: [:edit, :destroy, :update] do
    collection do
      get "/:kind", constraints: { kind: /submitted|saved_for_later|completed|cancelled/ }, as: '', to: 'aeon_requests#index'
      delete 'destroy_multiple'
      post :update_multiple
    end

    member do
      post :save_for_later
    end
  end

  resources :aeon_reading_rooms, only: [] do
    member do
      get 'available', to: 'aeon_reading_rooms#available', as: :available
      get 'unavailable_dates', to: 'aeon_reading_rooms#unavailable_dates', as: :unavailable_dates
    end
  end

  resources :aeon_appointments do
    get :items
  end

  get "/aeon_appointments/new/:reading_room_id", to: 'aeon_appointments#new', as: :new_aeon_appointment_for_reading_room

  resource :aeon_user, only: [:new, :create] do
    post :terms, to: 'aeon_users#accept_terms', as: :accept_terms
  end

  resources :aeon_activities, only: [:index] do
      collection { get :active; get :past }
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

  unless Rails.env.production?
    namespace :stub_aeon_client do
      get 'Users', to: 'users#index'
      get 'Users/:username', to: 'users#show', constraints: { username: /[^\/]+/ }
      get 'Users/:username/requests', to: 'requests#index', constraints: { username: /[^\/]+/ }
      get 'Users/:username/appointments', to: 'appointments#index', constraints: { username: /[^\/]+/ }
      post 'Users', to: 'users#create'

      get 'Activities', to: 'activities#index'
      get 'Queues', to: 'queues#index'

      post 'Requests/create', to: 'requests#create'
      patch 'Requests/:id', to: 'requests#update'
      post 'Requests/:id/route', to: 'requests#route'

      post 'Appointments', to: 'appointments#create'
      patch 'Appointments/:id', to: 'appointments#update'
      delete 'Appointments/:id', to: 'appointments#destroy'

      get 'ReadingRooms', to: 'reading_rooms#index'
      get 'ReadingRooms/:id/Closures', to: 'reading_rooms#closures'
      get 'ReadingRooms/:id/AvailableAppointments/:date', to: 'reading_rooms#available_appointments'
    end
  end

  mount Lookbook::Engine, at: "/lookbook"
  require 'sidekiq/web'
  require 'sidekiq_constraint'
  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new
end
