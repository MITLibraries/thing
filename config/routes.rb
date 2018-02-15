Rails.application.routes.draw do
  # For details see http://guides.rubyonrails.org/routing.html
  namespace :admin do
    resources :users
    resources :degrees
    resources :departments
    resources :rights
    resources :theses

    root to: "theses#index"
  end

  resources :thesis, only: [:new, :create, :show]
  get 'process', to: 'thesis#process_theses'
  get 'process/:status', to: 'thesis#process_theses'
  post 'done/:id', to: 'thesis#mark_downloaded',
                   id: /[0-9]+/,
                   as: 'mark_downloaded'
  post 'withdrawn/:id', to: 'thesis#mark_withdrawn',
                   id: /[0-9]+/,
                   as: 'mark_withdrawn'

  devise_for :users, :controllers => {
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :user_session
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  authenticated do
    root :to => 'thesis#new'
  end

  root to: 'static#index'
end
