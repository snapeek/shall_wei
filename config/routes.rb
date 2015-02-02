require 'sidekiq/web'
Rails.application.routes.draw do
  resources :keywords do
    member do
      get :search_day_count, :weibo, :new_search, :wpath, :baidu_news, :ctn_search
    end
  end

  resources :kibers

  resources :captchas

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Sidekiq::Web => '/sidekiq'
  root to: 'visitors#index'
end
