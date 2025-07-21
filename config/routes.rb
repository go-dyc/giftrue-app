Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route - redirect to Naver Smart Store
  root to: redirect("https://smartstore.naver.com/giftrue/products/12125003099")

  # Admin routes - MUST come before customer order routes
  namespace :admin do
    get "settings/index"
    get "settings/update"
    get "orders/index"
    get "orders/show"
    get "orders/update"
    get "sessions/new"
    get "sessions/create"
    get "sessions/destroy"
    get :login, to: "sessions#new"
    post :login, to: "sessions#create"
    delete :logout, to: "sessions#destroy"
    
    root "orders#index"
    
    # Settings routes
    get "settings", to: "settings#index"
    patch "settings", to: "settings#update"
    
    # API Test routes
    get "api_test", to: "api_test#index"
    get "api_test/connection", to: "api_test#test_connection"
    get "api_test/token", to: "api_test#test_token"
    get "api_test/order_check", to: "api_test#test_order_check"
    
    resources :orders, only: [:index, :show, :update, :destroy] do
      member do
        patch :update_status
        patch :update_delivery_days
      end
    end
  end

  # Customer order routes - MUST come after admin routes
  resources :orders, param: :naver_order_number, only: [:show, :new, :create, :edit, :update] do
    member do
      get :verify
      post :verify
      get :complete
      get :cancelled
      patch :update_step
      get :test_slack
      get :test_order_notification
    end
  end
  
  # Temporary ID-based route for testing
  get '/orders/id/:id', to: 'orders#show', as: :order_by_id
end
