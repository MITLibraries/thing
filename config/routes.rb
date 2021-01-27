Rails.application.routes.draw do
  # For details see http://guides.rubyonrails.org/routing.html
  namespace :admin do
    resources :users
    resources :advisors
    resources :degrees
    resources :departments
    resources :holds
    resources :hold_sources
    resources :rights
    resources :submitters
    resources :theses
    resources :transfers

    root to: "theses#index"
  end

  resources :thesis, only: [:new, :create, :show]
  get 'process', to: 'thesis#process_theses', as: 'process'
  get 'process/:status', to: 'thesis#process_theses'
  post 'done/:id', to: 'thesis#mark_downloaded',
                   id: /[0-9]+/,
                   as: 'mark_downloaded'
  post 'withdrawn/:id', to: 'thesis#mark_withdrawn',
                   id: /[0-9]+/,
                   as: 'mark_withdrawn'
  post 'annotate/:id', to: 'thesis#annotate',
                   id: /[0-9]+/,
                   as: 'annotate'
  get 'stats', to: 'thesis#stats', as: 'stats'

  devise_for :users, :controllers => {
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }

  resources :transfer, only: [:new, :create, :show]

  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :user_session
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # handle old vireo starting URLs
  get 'vireo', to: redirect('/')
  get 'vireo/:whatever', to: redirect('/')

  root to: 'static#index'
end
