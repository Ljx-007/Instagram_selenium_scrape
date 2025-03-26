Rails.application.routes.draw do
  # 设置主页路由指向话题列表
  root "topics#index"
  
  # 话题资源路由
  resources :topics, only: [:index, :show, :create, :destroy] do
    member do
      post :refresh
      post :cancel_refresh
    end
  end
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Action Cable路由
  mount ActionCable.server => '/cable'

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
