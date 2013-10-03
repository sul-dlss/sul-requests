SymphonyRequests::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  
  #map.namespace :admin do |admin|
  #  admin.resources :requestdefs 
  #  admin.resources :reqtests
  #  admin.resources :fields
  #  admin.resources :messages
  #  admin.resources :libraries
  #  admin.resources :pickupkeys, :member => { :show_libraries => :get, :save => :post }
  #end

  namespace :admin do
    resources :requestdefs, :reqtests, :fields, :messages, :libraries
    resources :pickupkeys do
      member do
        get 'show_libraries'
        post 'save'
      end
    end
  end
  
  
  #map.namespace :auth do |auth|
  #  auth.resources :requests
  #end
  
  namespace :auth do
    resources :requests
  end
  
  resources :requests
  
  # Following extra stuff isn't needed 
  #map.connect 'admin/:controller/:action/:id'
  #map.connect 'admin/:controller/:action/:id.:format'
  #map.connect 'admin/:controller/:id/:action'
  # Not sure whether following need to be changed to a Rails 3 format since they aren't specific
  #connect ':controller/:action/:id'
  #connect ':controller/:action/:id.:format'
  
end
