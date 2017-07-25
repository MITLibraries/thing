Rails.application.routes.draw do
  namespace :admin do
    resources :users
    resources :advisors
    resources :degrees
    resources :departments
    resources :rights
    resources :theses

    root to: "theses#index"
  end

  devise_for :users, :controllers => {
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }

  root to: 'static#index'
end
