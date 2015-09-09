Rails.application.routes.draw do
  resources :messages
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#show'

  #sorry page route
  get 'sorry/unable'

  # Auhtorization routes
  get 'webauth/login' => 'authorization#login', as: :login
  get 'webauth/logout' => 'authorization#logout', as: :logout

  resources :paging_schedule, only: :index
  get 'paging_schedule/:origin(/:destination)' => 'paging_schedule#show', as: :paging_schedule

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

  resources :requests, only: :new
  resources :pages, concerns: [:creatable_via_get_redirect, :successable, :statusable]
  resources :scans, concerns: [:creatable_via_get_redirect, :successable, :statusable]
  resources :mediated_pages, concerns: [:creatable_via_get_redirect, :successable, :statusable]
  resources :hold_recalls, concerns: [:creatable_via_get_redirect, :successable, :statusable]

  resources :admin, only: [:index, :show] do
    member do
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
