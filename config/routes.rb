Rails.application.routes.draw do
  # For details see http://guides.rubyonrails.org/routing.html
  namespace :admin do
    resources :users
    resources :advisors
    resources :authors
    resources :copyrights
    resources :degrees
    resources :degree_types
    resources :departments
    resources :department_theses
    resources :holds
    resources :hold_sources
    resources :licenses
    resources :submitters
    resources :theses
    resources :transfers

    root to: "theses#index"
  end

  get 'thesis/start', to: 'thesis#start', as: 'thesis_start'
  get 'thesis/confirm', to: 'thesis#confirm', as: 'thesis_confirm'
  get 'thesis/select', to: 'thesis#select', as: 'thesis_select'
  resources :registrar, only: [:new, :create, :show]
  resources :thesis, only: [:new, :create, :edit, :show, :update]
  get 'harvest', to: 'registrar#list_registrar', as: 'harvest'
  get 'harvest/:id', to: 'registrar#process_registrar',
                     as: 'process_registrar'
  get 'hold_history/:id', to: 'hold#show', as: 'hold_history'

  devise_for :users, :controllers => {
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }

  get 'transfer/confirm', to: 'transfer#confirm', as: 'transfer_confirm'
  post 'transfer/files', to: 'transfer#files', as: 'transfer_files'
  get 'transfer/select', to: 'transfer#select', as: 'transfer_select'
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
