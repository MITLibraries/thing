Rails.application.routes.draw do
  # For details see http://guides.rubyonrails.org/routing.html
  namespace :admin do
    resources :users
    resources :archivematica_accessions
    resources :advisors
    resources :authors
    resources :copyrights
    resources :degrees
    resources :degree_types
    resources :degree_periods
    resources :departments
    resources :department_theses
    resources :holds
    resources :hold_sources
    resources :licenses
    resources :submission_information_packages
    resources :submitters
    resources :theses
    resources :transfers

    root to: "theses#index"
  end

  get 'report', to: 'report#index', as: 'report_index'
  get 'report/authors_not_graduated', to: 'report#authors_not_graduated', as: 'report_authors_not_graduated'
  get 'report/empty_theses', to: 'report#empty_theses', as: 'report_empty_theses'
  get 'report/expired_holds', to: 'report#expired_holds', as: 'report_expired_holds'
  get 'report/files', to: 'report#files', as: 'report_files'
  get 'report/holds_by_source', to: 'report#holds_by_source', as: 'report_holds_by_source'
  get 'report/proquest_files', to: 'report#proquest_files', as: 'report_proquest_files'
  get 'report/proquest_status', to: 'report#proquest_status', as: 'report_proquest_status'
  get 'report/student_submitted_theses', to: 'report#student_submitted_theses', as: 'report_student_submitted_theses'
  get 'report/term', to: 'report#term', as: 'report_term'
  get 'thesis/confirm', to: 'thesis#confirm', as: 'thesis_confirm'
  get 'thesis/deduplicate', to: 'thesis#deduplicate', as: 'thesis_deduplicate'
  get 'thesis/publication_statuses', to: 'thesis#publication_statuses', as: 'thesis_publication_statuses'
  get 'thesis/:id/process', to: 'thesis#process_theses', as: 'thesis_process'
  patch 'thesis/:id/process', to: 'thesis#process_theses_update', as: 'thesis_process_update'
  get 'thesis/publish_preview', to: 'thesis#publish_preview', as: 'thesis_publish_preview'
  get 'thesis/publish', to: 'thesis#publish_to_dspace', as: 'thesis_publish_to_dspace'
  get 'thesis/select', to: 'thesis#select', as: 'thesis_select'
  get 'thesis/start', to: 'thesis#start', as: 'thesis_start'
  get 'thesis/proquest_export_preview', to: 'thesis#proquest_export_preview', as: 'thesis_proquest_export_preview'
  get 'thesis/proquest_export', to: 'thesis#proquest_export', as: 'thesis_proquest_export'
  get 'thesis/reset_all_publication_errors', to: 'thesis#reset_all_publication_errors', as: 'reset_all_publication_errors'
  
  # Blob file renaming
  get 'file/rename/:thesis_id/:attachment_id', to: 'file#rename_form', as: 'rename_file_form'
  post 'file/rename/:thesis_id/:attachment_id', to: 'file#rename', as: 'rename_file'

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


  get 'login', to: 'static#login', as: 'login'
  root to: 'static#index'
end
