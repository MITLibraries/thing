class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    # See the documentation for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/Defining-Abilities.md

    if user.present?
      @user = user
      # Admin users can do everything for all models
      can :manage, :all if user.admin?

      # Assign thesis_submitter rights directly to appropriate users as the
      # process that follows will not pick them up as it is not an explicitly
      # assigned role
      transfer_submitter if user.submitter?

      # This line matches users' roles with the functions defined below,
      # giving them privileges accordingly.
      send(@user.role.to_sym)
    end
  end

  # The default; any logged-in user. The use case here is students uploading
  # their theses.
  def basic
    # Any user can create a new Thesis.
    can :create, Thesis
    can :start, Thesis
    can :confirm, Thesis

    # Only the Thesis author can view their Thesis.
    can :read, Thesis, users: { id: @user.id }
    can :update, Thesis, users: { id: @user.id }
  end

  # Users who can submit and view transfers.
  def transfer_submitter
    basic
    can :create, Transfer
    can :confirm, Transfer
  end

  # Library staff who process the thesis queue. They should be able to use the
  # submissions processing queue page and whatever functionality it exposes,
  # but not the admin dashboards.
  def processor
    basic

    can 'index', :all
    can 'show', :all

    # Allow processors to see the admin dashboard link in the main site nav. See the _site_nav layout for more info.
    can :administrate, Admin

    # Authorize processors to use all submitter dashboard controller actions. If not, any attempts to access the
    # dashboard will trigger Admin::ApplicationController#authorized_or_redirect.
    can :manage, :submitter

    # Authorize processors to access submitter model. If not, administrate will raise a NotAuthorizedError when
    # controller methods are called.
    can :manage, Submitter

    can :files, Report
    can :proquest_files, Report
    can :index, Report
    can :term, Report
    can :empty_theses, Report
    can :expired_holds, Report
    can :holds_by_source, Report
    can :student_submitted_theses, Report
    can :authors_not_graduated, Report
    can :proquest_status, Report

    can %i[read update], Thesis
    can :annotate, Thesis
    can :deduplicate, Thesis
    can :mark_downloaded, Thesis
    can :mark_withdrawn, Thesis
    can :process_theses, Thesis
    can :process_theses_update, Thesis
    can :publish_preview, Thesis
    can :publish_to_dspace, Thesis
    can :select, Thesis
    can :publication_statuses, Thesis

    can :read, Transfer
    can :select, Transfer
    can :files, Transfer

    can :read, Hold
  end

  # Library staff who can use the admin dashboards (which includes operations
  # on departments).
  def thesis_admin
    processor

    can :manage, :all
    cannot 'destroy', :copyright
    cannot 'destroy', :degree
    cannot 'destroy', :department
    cannot 'destroy', :hold_source
    cannot 'destroy', :license
    cannot 'destroy', :submission_information_package
    cannot 'update', :submission_information_package
    cannot 'edit', :submission_information_package
  end
end
