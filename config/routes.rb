# config/routes.rb
Rails.application.routes.draw do
  # L'inscription publique est fermée : les comptes sont créés par l'admin.
  devise_for :users, skip: [:registrations]

  devise_scope :user do
    get "compte/edition" => "devise/registrations#edit",   as: :edit_user_registration
    put "compte"         => "devise/registrations#update", as: :user_registration
  end

  authenticated :user do
    root to: "dashboard#index", as: :dashboard
  end

  unauthenticated do
    root to: redirect("/users/sign_in"), as: :unauthenticated_root
  end

  get "statistiques", to: "stats#index", as: :stats

  resources :children do
    member { get :stats }

    get   "assignation", to: "child_items#bulk_edit",   as: :bulk_edit_items
    patch "assignation", to: "child_items#bulk_update", as: :bulk_update_items

    resources :child_items, shallow: true

    resources :weeks, only: %i[index show] do
      member { patch :finalize }
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
