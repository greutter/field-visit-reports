Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  # Dashboard
  root "dashboard#index"

  # Fields and Field Visits
  resources :fields do
    resources :field_visits, only: %i[index show new create destroy] do
      member do
        post :generate_report
      end
      resources :audio_messages, only: %i[create destroy] do
        member do
          post :transcribe
        end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
