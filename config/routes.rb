Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route
  root "orders#new"

  # Admin routes - MUST come before customer order routes
  namespace :admin do
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
    resources :orders, only: [:index, :show, :update] do
      member do
        patch :update_status
      end
    end
  end

  # Customer order routes - MUST come after admin routes
  resources :orders, param: :naver_order_number, only: [:show, :new, :create, :edit, :update] do
    member do
      get :complete
      patch :update_step
    end
  end
end
