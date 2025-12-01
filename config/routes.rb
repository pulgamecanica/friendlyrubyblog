Rails.application.routes.draw do
  # Mount ActionCable for WebSocket connections
  mount ActionCable.server => "/cable"

  devise_for :authors, path: "author", path_names: { sign_in: "sign_in", sign_out: "sign_out" }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "public/documents#index", defaults: { kind: "post" }

  namespace :public, path: "" do
    root "documents#index", defaults: { kind: "post" }

    resources :series,    only: [ :index, :show ]
    resources :tags,      only: [ :show ] # /tags/:id => tag documents

    # Document type-specific routes
    resources :posts, controller: "documents", only: [ :index, :show ], defaults: { kind: "post" } do
      resources :comments, only: [ :create ]
      resource  :like,     only: [ :create, :destroy ]
    end

    resources :pages, controller: "pages", only: [ :index, :show ] do
      resources :comments, only: [ :create ]
      resource  :like,     only: [ :create, :destroy ]
    end

    resources :notes, controller: "notes", only: [ :index, :show ] do
      resources :comments, only: [ :create ]
      resource  :like,     only: [ :create, :destroy ]
    end

    # Fallback for generic documents (backwards compatibility)
    resources :documents, only: [ :index, :show ] do
      resources :comments, only: [ :create ]
      resource  :like,     only: [ :create, :destroy ]
    end

    resources :blocks, only: [] do
      resource  :like,     only: [ :create, :destroy ]
    end
  end

  namespace :author do
    root "dashboard#index"

    get "dashboard", to: "dashboard#index", as: :dashboard
    get "analytics", to: "analytics#index", as: :analytics
    get "analytics/visitor/:id", to: "analytics#visitor", as: :analytics_visitor

    resources :series do
      member do
        delete :remove_portrait
      end
    end
    resources :documents do
      member do
        patch :publish
        patch :unpublish
        delete :remove_portrait
      end
      resources :blocks, only: [ :create, :update, :destroy ] do
        collection do
          post :preview
          patch :sort
        end
        member do
          delete "images/:attachment_id", to: "blocks#remove_image", as: :remove_image
          post :execute
          patch :toggle_interactive
          post :compile_mlx42
          post :import_mlx42_files
          post :export_mlx42_files
          get :versions
          get :show
          get "versions/:version_id/preview", to: "blocks#preview_version", as: :preview_version
          patch "versions/:version_id/restore", to: "blocks#restore_version", as: :restore_version
          patch :undo
          patch :redo
        end
      end
    end

    # Separate routes for document types
    resources :posts, controller: "documents", defaults: { kind: "post" }
    resources :notes, controller: "documents", defaults: { kind: "note" }
    resources :pages, controller: "documents", defaults: { kind: "page" }

    resources :comments, only: [ :index, :update, :destroy ]
  end
end
