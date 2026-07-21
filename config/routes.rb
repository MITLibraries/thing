# == Route Map
#
# Routes for application:
#                                    Prefix Verb     URI Pattern                                                                                       Controller#Action
#                        rails_health_check GET      /up(.:format)                                                                                     rails/health#show
#                                  flipflop          /flipflop                                                                                         Flipflop::Engine
#                               admin_users GET      /admin/users(.:format)                                                                            admin/users#index
#                                           POST     /admin/users(.:format)                                                                            admin/users#create
#                            new_admin_user GET      /admin/users/new(.:format)                                                                        admin/users#new
#                           edit_admin_user GET      /admin/users/:id/edit(.:format)                                                                   admin/users#edit
#                                admin_user GET      /admin/users/:id(.:format)                                                                        admin/users#show
#                                           PATCH    /admin/users/:id(.:format)                                                                        admin/users#update
#                                           PUT      /admin/users/:id(.:format)                                                                        admin/users#update
#                                           DELETE   /admin/users/:id(.:format)                                                                        admin/users#destroy
#            admin_archivematica_accessions GET      /admin/archivematica_accessions(.:format)                                                         admin/archivematica_accessions#index
#                                           POST     /admin/archivematica_accessions(.:format)                                                         admin/archivematica_accessions#create
#         new_admin_archivematica_accession GET      /admin/archivematica_accessions/new(.:format)                                                     admin/archivematica_accessions#new
#        edit_admin_archivematica_accession GET      /admin/archivematica_accessions/:id/edit(.:format)                                                admin/archivematica_accessions#edit
#             admin_archivematica_accession GET      /admin/archivematica_accessions/:id(.:format)                                                     admin/archivematica_accessions#show
#                                           PATCH    /admin/archivematica_accessions/:id(.:format)                                                     admin/archivematica_accessions#update
#                                           PUT      /admin/archivematica_accessions/:id(.:format)                                                     admin/archivematica_accessions#update
#                                           DELETE   /admin/archivematica_accessions/:id(.:format)                                                     admin/archivematica_accessions#destroy
#                            admin_advisors GET      /admin/advisors(.:format)                                                                         admin/advisors#index
#                                           POST     /admin/advisors(.:format)                                                                         admin/advisors#create
#                         new_admin_advisor GET      /admin/advisors/new(.:format)                                                                     admin/advisors#new
#                        edit_admin_advisor GET      /admin/advisors/:id/edit(.:format)                                                                admin/advisors#edit
#                             admin_advisor GET      /admin/advisors/:id(.:format)                                                                     admin/advisors#show
#                                           PATCH    /admin/advisors/:id(.:format)                                                                     admin/advisors#update
#                                           PUT      /admin/advisors/:id(.:format)                                                                     admin/advisors#update
#                                           DELETE   /admin/advisors/:id(.:format)                                                                     admin/advisors#destroy
#                             admin_authors GET      /admin/authors(.:format)                                                                          admin/authors#index
#                                           POST     /admin/authors(.:format)                                                                          admin/authors#create
#                          new_admin_author GET      /admin/authors/new(.:format)                                                                      admin/authors#new
#                         edit_admin_author GET      /admin/authors/:id/edit(.:format)                                                                 admin/authors#edit
#                              admin_author GET      /admin/authors/:id(.:format)                                                                      admin/authors#show
#                                           PATCH    /admin/authors/:id(.:format)                                                                      admin/authors#update
#                                           PUT      /admin/authors/:id(.:format)                                                                      admin/authors#update
#                                           DELETE   /admin/authors/:id(.:format)                                                                      admin/authors#destroy
#                          admin_copyrights GET      /admin/copyrights(.:format)                                                                       admin/copyrights#index
#                                           POST     /admin/copyrights(.:format)                                                                       admin/copyrights#create
#                       new_admin_copyright GET      /admin/copyrights/new(.:format)                                                                   admin/copyrights#new
#                      edit_admin_copyright GET      /admin/copyrights/:id/edit(.:format)                                                              admin/copyrights#edit
#                           admin_copyright GET      /admin/copyrights/:id(.:format)                                                                   admin/copyrights#show
#                                           PATCH    /admin/copyrights/:id(.:format)                                                                   admin/copyrights#update
#                                           PUT      /admin/copyrights/:id(.:format)                                                                   admin/copyrights#update
#                                           DELETE   /admin/copyrights/:id(.:format)                                                                   admin/copyrights#destroy
#                             admin_degrees GET      /admin/degrees(.:format)                                                                          admin/degrees#index
#                                           POST     /admin/degrees(.:format)                                                                          admin/degrees#create
#                          new_admin_degree GET      /admin/degrees/new(.:format)                                                                      admin/degrees#new
#                         edit_admin_degree GET      /admin/degrees/:id/edit(.:format)                                                                 admin/degrees#edit
#                              admin_degree GET      /admin/degrees/:id(.:format)                                                                      admin/degrees#show
#                                           PATCH    /admin/degrees/:id(.:format)                                                                      admin/degrees#update
#                                           PUT      /admin/degrees/:id(.:format)                                                                      admin/degrees#update
#                                           DELETE   /admin/degrees/:id(.:format)                                                                      admin/degrees#destroy
#                        admin_degree_types GET      /admin/degree_types(.:format)                                                                     admin/degree_types#index
#                                           POST     /admin/degree_types(.:format)                                                                     admin/degree_types#create
#                     new_admin_degree_type GET      /admin/degree_types/new(.:format)                                                                 admin/degree_types#new
#                    edit_admin_degree_type GET      /admin/degree_types/:id/edit(.:format)                                                            admin/degree_types#edit
#                         admin_degree_type GET      /admin/degree_types/:id(.:format)                                                                 admin/degree_types#show
#                                           PATCH    /admin/degree_types/:id(.:format)                                                                 admin/degree_types#update
#                                           PUT      /admin/degree_types/:id(.:format)                                                                 admin/degree_types#update
#                                           DELETE   /admin/degree_types/:id(.:format)                                                                 admin/degree_types#destroy
#                      admin_degree_periods GET      /admin/degree_periods(.:format)                                                                   admin/degree_periods#index
#                                           POST     /admin/degree_periods(.:format)                                                                   admin/degree_periods#create
#                   new_admin_degree_period GET      /admin/degree_periods/new(.:format)                                                               admin/degree_periods#new
#                  edit_admin_degree_period GET      /admin/degree_periods/:id/edit(.:format)                                                          admin/degree_periods#edit
#                       admin_degree_period GET      /admin/degree_periods/:id(.:format)                                                               admin/degree_periods#show
#                                           PATCH    /admin/degree_periods/:id(.:format)                                                               admin/degree_periods#update
#                                           PUT      /admin/degree_periods/:id(.:format)                                                               admin/degree_periods#update
#                                           DELETE   /admin/degree_periods/:id(.:format)                                                               admin/degree_periods#destroy
#                         admin_departments GET      /admin/departments(.:format)                                                                      admin/departments#index
#                                           POST     /admin/departments(.:format)                                                                      admin/departments#create
#                      new_admin_department GET      /admin/departments/new(.:format)                                                                  admin/departments#new
#                     edit_admin_department GET      /admin/departments/:id/edit(.:format)                                                             admin/departments#edit
#                          admin_department GET      /admin/departments/:id(.:format)                                                                  admin/departments#show
#                                           PATCH    /admin/departments/:id(.:format)                                                                  admin/departments#update
#                                           PUT      /admin/departments/:id(.:format)                                                                  admin/departments#update
#                                           DELETE   /admin/departments/:id(.:format)                                                                  admin/departments#destroy
#                   admin_department_theses GET      /admin/department_theses(.:format)                                                                admin/department_theses#index
#                                           POST     /admin/department_theses(.:format)                                                                admin/department_theses#create
#               new_admin_department_thesis GET      /admin/department_theses/new(.:format)                                                            admin/department_theses#new
#              edit_admin_department_thesis GET      /admin/department_theses/:id/edit(.:format)                                                       admin/department_theses#edit
#                   admin_department_thesis GET      /admin/department_theses/:id(.:format)                                                            admin/department_theses#show
#                                           PATCH    /admin/department_theses/:id(.:format)                                                            admin/department_theses#update
#                                           PUT      /admin/department_theses/:id(.:format)                                                            admin/department_theses#update
#                                           DELETE   /admin/department_theses/:id(.:format)                                                            admin/department_theses#destroy
#                               admin_holds GET      /admin/holds(.:format)                                                                            admin/holds#index
#                                           POST     /admin/holds(.:format)                                                                            admin/holds#create
#                            new_admin_hold GET      /admin/holds/new(.:format)                                                                        admin/holds#new
#                           edit_admin_hold GET      /admin/holds/:id/edit(.:format)                                                                   admin/holds#edit
#                                admin_hold GET      /admin/holds/:id(.:format)                                                                        admin/holds#show
#                                           PATCH    /admin/holds/:id(.:format)                                                                        admin/holds#update
#                                           PUT      /admin/holds/:id(.:format)                                                                        admin/holds#update
#                                           DELETE   /admin/holds/:id(.:format)                                                                        admin/holds#destroy
#                        admin_hold_sources GET      /admin/hold_sources(.:format)                                                                     admin/hold_sources#index
#                                           POST     /admin/hold_sources(.:format)                                                                     admin/hold_sources#create
#                     new_admin_hold_source GET      /admin/hold_sources/new(.:format)                                                                 admin/hold_sources#new
#                    edit_admin_hold_source GET      /admin/hold_sources/:id/edit(.:format)                                                            admin/hold_sources#edit
#                         admin_hold_source GET      /admin/hold_sources/:id(.:format)                                                                 admin/hold_sources#show
#                                           PATCH    /admin/hold_sources/:id(.:format)                                                                 admin/hold_sources#update
#                                           PUT      /admin/hold_sources/:id(.:format)                                                                 admin/hold_sources#update
#                                           DELETE   /admin/hold_sources/:id(.:format)                                                                 admin/hold_sources#destroy
#                            admin_licenses GET      /admin/licenses(.:format)                                                                         admin/licenses#index
#                                           POST     /admin/licenses(.:format)                                                                         admin/licenses#create
#                         new_admin_license GET      /admin/licenses/new(.:format)                                                                     admin/licenses#new
#                        edit_admin_license GET      /admin/licenses/:id/edit(.:format)                                                                admin/licenses#edit
#                             admin_license GET      /admin/licenses/:id(.:format)                                                                     admin/licenses#show
#                                           PATCH    /admin/licenses/:id(.:format)                                                                     admin/licenses#update
#                                           PUT      /admin/licenses/:id(.:format)                                                                     admin/licenses#update
#                                           DELETE   /admin/licenses/:id(.:format)                                                                     admin/licenses#destroy
#     admin_submission_information_packages GET      /admin/submission_information_packages(.:format)                                                  admin/submission_information_packages#index
#                                           POST     /admin/submission_information_packages(.:format)                                                  admin/submission_information_packages#create
#  new_admin_submission_information_package GET      /admin/submission_information_packages/new(.:format)                                              admin/submission_information_packages#new
# edit_admin_submission_information_package GET      /admin/submission_information_packages/:id/edit(.:format)                                         admin/submission_information_packages#edit
#      admin_submission_information_package GET      /admin/submission_information_packages/:id(.:format)                                              admin/submission_information_packages#show
#                                           PATCH    /admin/submission_information_packages/:id(.:format)                                              admin/submission_information_packages#update
#                                           PUT      /admin/submission_information_packages/:id(.:format)                                              admin/submission_information_packages#update
#                                           DELETE   /admin/submission_information_packages/:id(.:format)                                              admin/submission_information_packages#destroy
#                          admin_submitters GET      /admin/submitters(.:format)                                                                       admin/submitters#index
#                                           POST     /admin/submitters(.:format)                                                                       admin/submitters#create
#                       new_admin_submitter GET      /admin/submitters/new(.:format)                                                                   admin/submitters#new
#                      edit_admin_submitter GET      /admin/submitters/:id/edit(.:format)                                                              admin/submitters#edit
#                           admin_submitter GET      /admin/submitters/:id(.:format)                                                                   admin/submitters#show
#                                           PATCH    /admin/submitters/:id(.:format)                                                                   admin/submitters#update
#                                           PUT      /admin/submitters/:id(.:format)                                                                   admin/submitters#update
#                                           DELETE   /admin/submitters/:id(.:format)                                                                   admin/submitters#destroy
#                              admin_theses GET      /admin/theses(.:format)                                                                           admin/theses#index
#                                           POST     /admin/theses(.:format)                                                                           admin/theses#create
#                          new_admin_thesis GET      /admin/theses/new(.:format)                                                                       admin/theses#new
#                         edit_admin_thesis GET      /admin/theses/:id/edit(.:format)                                                                  admin/theses#edit
#                              admin_thesis GET      /admin/theses/:id(.:format)                                                                       admin/theses#show
#                                           PATCH    /admin/theses/:id(.:format)                                                                       admin/theses#update
#                                           PUT      /admin/theses/:id(.:format)                                                                       admin/theses#update
#                                           DELETE   /admin/theses/:id(.:format)                                                                       admin/theses#destroy
#                           admin_transfers GET      /admin/transfers(.:format)                                                                        admin/transfers#index
#                                           POST     /admin/transfers(.:format)                                                                        admin/transfers#create
#                        new_admin_transfer GET      /admin/transfers/new(.:format)                                                                    admin/transfers#new
#                       edit_admin_transfer GET      /admin/transfers/:id/edit(.:format)                                                               admin/transfers#edit
#                            admin_transfer GET      /admin/transfers/:id(.:format)                                                                    admin/transfers#show
#                                           PATCH    /admin/transfers/:id(.:format)                                                                    admin/transfers#update
#                                           PUT      /admin/transfers/:id(.:format)                                                                    admin/transfers#update
#                                           DELETE   /admin/transfers/:id(.:format)                                                                    admin/transfers#destroy
#                                admin_root GET      /admin(.:format)                                                                                  admin/theses#index
#                              report_index GET      /report(.:format)                                                                                 report#index
#              report_authors_not_graduated GET      /report/authors_not_graduated(.:format)                                                           report#authors_not_graduated
#                       report_empty_theses GET      /report/empty_theses(.:format)                                                                    report#empty_theses
#                      report_expired_holds GET      /report/expired_holds(.:format)                                                                   report#expired_holds
#                              report_files GET      /report/files(.:format)                                                                           report#files
#                    report_holds_by_source GET      /report/holds_by_source(.:format)                                                                 report#holds_by_source
#                     report_proquest_files GET      /report/proquest_files(.:format)                                                                  report#proquest_files
#                    report_proquest_status GET      /report/proquest_status(.:format)                                                                 report#proquest_status
#           report_student_submitted_theses GET      /report/student_submitted_theses(.:format)                                                        report#student_submitted_theses
#                               report_term GET      /report/term(.:format)                                                                            report#term
#                            thesis_confirm GET      /thesis/confirm(.:format)                                                                         thesis#confirm
#                        thesis_deduplicate GET      /thesis/deduplicate(.:format)                                                                     thesis#deduplicate
#               thesis_publication_statuses GET      /thesis/publication_statuses(.:format)                                                            thesis#publication_statuses
#                            thesis_process GET      /thesis/:id/process(.:format)                                                                     thesis#process_theses
#                     thesis_process_update PATCH    /thesis/:id/process(.:format)                                                                     thesis#process_theses_update
#                    thesis_publish_preview GET      /thesis/publish_preview(.:format)                                                                 thesis#publish_preview
#                  thesis_publish_to_dspace GET      /thesis/publish(.:format)                                                                         thesis#publish_to_dspace
#                             thesis_select GET      /thesis/select(.:format)                                                                          thesis#select
#                              thesis_start GET      /thesis/start(.:format)                                                                           thesis#start
#            thesis_proquest_export_preview GET      /thesis/proquest_export_preview(.:format)                                                         thesis#proquest_export_preview
#                    thesis_proquest_export GET      /thesis/proquest_export(.:format)                                                                 thesis#proquest_export
#              reset_all_publication_errors GET      /thesis/reset_all_publication_errors(.:format)                                                    thesis#reset_all_publication_errors
#                          rename_file_form GET      /file/rename/:thesis_id/:attachment_id(.:format)                                                  file#rename_form
#                               rename_file POST     /file/rename/:thesis_id/:attachment_id(.:format)                                                  file#rename
#                           registrar_index POST     /registrar(.:format)                                                                              registrar#create
#                             new_registrar GET      /registrar/new(.:format)                                                                          registrar#new
#                                 registrar GET      /registrar/:id(.:format)                                                                          registrar#show
#                              thesis_index POST     /thesis(.:format)                                                                                 thesis#create
#                                new_thesis GET      /thesis/new(.:format)                                                                             thesis#new
#                               edit_thesis GET      /thesis/:id/edit(.:format)                                                                        thesis#edit
#                                    thesis GET      /thesis/:id(.:format)                                                                             thesis#show
#                                           PATCH    /thesis/:id(.:format)                                                                             thesis#update
#                                           PUT      /thesis/:id(.:format)                                                                             thesis#update
#                                   harvest GET      /harvest(.:format)                                                                                registrar#list_registrar
#                         process_registrar GET      /harvest/:id(.:format)                                                                            registrar#process_registrar
#                              hold_history GET      /hold_history/:id(.:format)                                                                       hold#show
#         user_developer_omniauth_authorize POST     /users/auth/developer(.:format)                                                                   users/omniauth_callbacks#passthru
#          user_developer_omniauth_callback GET|POST /users/auth/developer/callback(.:format)                                                          users/omniauth_callbacks#developer
#                          transfer_confirm GET      /transfer/confirm(.:format)                                                                       transfer#confirm
#                            transfer_files POST     /transfer/files(.:format)                                                                         transfer#files
#                           transfer_select GET      /transfer/select(.:format)                                                                        transfer#select
#                            transfer_index POST     /transfer(.:format)                                                                               transfer#create
#                              new_transfer GET      /transfer/new(.:format)                                                                           transfer#new
#                                  transfer GET      /transfer/:id(.:format)                                                                           transfer#show
#                              user_session GET      /sign_in(.:format)                                                                                devise/sessions#new
#                      destroy_user_session DELETE   /sign_out(.:format)                                                                               devise/sessions#destroy
#                                     vireo GET      /vireo(.:format)                                                                                  redirect(301, /)
#                                           GET      /vireo/:whatever(.:format)                                                                        redirect(301, /)
#                                     login GET      /login(.:format)                                                                                  static#login
#                                      root GET      /                                                                                                 static#index
#             rails_postmark_inbound_emails POST     /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#                rails_relay_inbound_emails POST     /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#             rails_sendgrid_inbound_emails POST     /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#       rails_mandrill_inbound_health_check GET      /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#             rails_mandrill_inbound_emails POST     /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#              rails_mailgun_inbound_emails POST     /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#            rails_conductor_inbound_emails GET      /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                           POST     /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#         new_rails_conductor_inbound_email GET      /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#             rails_conductor_inbound_email GET      /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
#  new_rails_conductor_inbound_email_source GET      /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#     rails_conductor_inbound_email_sources POST     /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#     rails_conductor_inbound_email_reroute POST     /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
#  rails_conductor_inbound_email_incinerate POST     /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                        rails_service_blob GET      /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                  rails_service_blob_proxy GET      /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                           GET      /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                 rails_blob_representation GET      /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#           rails_blob_representation_proxy GET      /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                           GET      /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                        rails_disk_service GET      /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                 update_rails_disk_service PUT      /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                      rails_direct_uploads POST     /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for Flipflop::Engine:
#           Prefix Verb   URI Pattern                           Controller#Action
# feature_strategy PATCH  /:feature_id/strategies/:id(.:format) flipflop/strategies#update
#                  PUT    /:feature_id/strategies/:id(.:format) flipflop/strategies#update
#                  DELETE /:feature_id/strategies/:id(.:format) flipflop/strategies#destroy
#         features GET    /                                     flipflop/features#index

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount Flipflop::Engine => "/flipflop"
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
