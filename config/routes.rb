Rails.application.routes.draw do
  resources :messages
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'

  require 'sidekiq/web'
  require 'sidekiq_constraint'
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new

  get 'interstitial' => 'interstitial#show', as: :interstitial

  # Authorization routes
  get 'webauth/login' => 'authentication#login', as: :login
  get 'webauth/logout' => 'authentication#logout', as: :logout

  resources :paging_schedule, only: :index
  get 'paging_schedule/:origin(/:destination)' => 'paging_schedule#show', as: :paging_schedule
  get 'paging_schedule/:origin/:destination/:date' => 'paging_schedule#open', as: :open_hours

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

  concern :eligibility_checkable do
    collection do
      get :ineligible, as: :ineligible
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
  resources :pages, concerns: [:creatable_via_get_redirect, :eligibility_checkable, :successable, :statusable]
  resources :scans, concerns: [:creatable_via_get_redirect, :eligibility_checkable, :successable, :statusable]
  resources :mediated_pages, concerns: [:admin_commentable, :creatable_via_get_redirect, :eligibility_checkable, :successable, :statusable]
  resources :hold_recalls, concerns: [:creatable_via_get_redirect, :eligibility_checkable, :successable, :statusable]

  resources :admin, only: [:index, :show] do
    member do
      get :picklist
      get :holdings, as: :holdings
      get :approve_item, as: :approve_item
    end
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
