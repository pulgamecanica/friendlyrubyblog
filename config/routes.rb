Rails.application.routes.draw do
  devise_for :authors, path: "author", path_names: { sign_in: "sign_in", sign_out: "sign_out" }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root to: "public/documents#index"

  namespace :public, path: "" do
    root "documents#index"

    resources :series,    only: [ :index, :show ]
    resources :tags,      only: [ :show ] # /tags/:id => tag documents
    resources :documents, only: [ :index, :show ] do
      resources :comments, only: [ :create ]
      resource  :like,     only: [ :create, :destroy ]
    end

    resources :blocks, only: [] do
      resource  :like,     only: [ :create, :destroy ]
    end
  end

  namespace :author do
    root "documents#index"
    resources :series
    resources :documents do
      member do
        patch :publish
        patch :unpublish
      end
      resources :blocks, only: [ :create, :update, :destroy ] do
        collection do
          post :preview
          patch :sort
        end
      end
    end
    resources :comments, only: [ :index, :update, :destroy ]
  end
end
