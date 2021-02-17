class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    # See the documentation for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.present?
      @user = user
      # Admin users can do everything for all models
      if user.admin?
        can :manage, :all
      end

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

    # Only the Thesis author can view their Thesis.
    can :read, Thesis, users: { id: @user.id }
  end

  # Users who can submit and view transfers.
  def transfer_submitter
    basic
    can :create, Transfer
    can :read, Transfer, user_id: @user.id
  end

  # Library staff who process the thesis queue. They should be able to use the
  # submissions processing queue page and whatever functionality it exposes,
  # but not the admin dashboards.
  def processor
    basic
    can :mark_downloaded, Thesis
    can :mark_withdrawn, Thesis
    can :annotate, Thesis
    can :process_theses, Thesis
    can :stats, Thesis
    can :read, Thesis
    can :read, Transfer
  end

  # Library staff who can use the admin dashboards (which includes operations
  # on departments).
  def thesis_admin
    processor
    can %i[create update], Thesis
    can :create, Transfer
    can :read, Transfer
    can :administrate, Admin
    can :create, Registrar
    can :read, Registrar
  end
end
