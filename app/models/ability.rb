class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.
    # See the documentation for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.present?
      # Any user can create a new Thesis
      can :create, Thesis

      # Only the Thesis owner can view their Thesis
      can :read, Thesis, user_id: user.id

      # Admin users can do everything for all models
      if user.admin?
        can :manage, :all
      end

      # Define :process role here
      # They should be able to view submissions and mark theses as done
      # Should they be able to mark theses as withdrawn, or is that admin only?
    end
  end
end
