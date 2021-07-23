require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    theses: Field::HasMany,
    id: Field::Number,
    uid: Field::String,
    kerberos_id: Field::String,
    orcid: Field::String,
    email: Field::String,
    admin: Field::Boolean,
    preferred_name: Field::String,
    given_name: Field::String,
    middle_name: Field::String,
    surname: Field::String,
    display_name: Field::String,
    submitters: UserSubmitterField,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    role: Field::Select.with_options(
      collection: User::ROLES
    )
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    display_name
    email
    kerberos_id
    role
    theses
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    display_name
    theses
    uid
    kerberos_id
    orcid
    email
    admin
    submitters
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    preferred_name
    given_name
    middle_name
    surname
    kerberos_id
    orcid
    theses
    email
    admin
    role
  ].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    if user.preferred_name.present?
      user.preferred_name.to_s
    elsif user.given_name.present? && user.surname.present?
      "#{user.given_name} #{user.surname}"
    else
      user.email
    end
  end
end
