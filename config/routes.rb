
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "dashboard#index", as: :dashboard
  end

  devise_scope :user do
    unauthenticated do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end

  resources :children do
    resources :child_items, shallow: true

    resources :weeks, only: %i[index show] do
      member do
        patch :finalize
      end
      resources :day_entries, only: %i[update]
    end

    resources :point_transactions, only: %i[index new create]
  end

  resources :items
  resources :privileges

  namespace :admin do
    resources :users
    root to: "users#index"
  end
end
