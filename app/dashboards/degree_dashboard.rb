require 'administrate/base_dashboard'

class DegreeDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    theses: Field::HasMany,
    id: Field::Number,
    name_dw: Field::String,
    code_dw: Field::String,
    abbreviation: Field::String,
    name_dspace: Field::String,
    degree_type: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    theses
    id
    name_dw
    name_dspace
    created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    theses
    id
    name_dw
    code_dw
    abbreviation
    name_dspace
    degree_type
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    theses
    name_dspace
    abbreviation
    degree_type
  ].freeze

  # Overwrite this method to customize how degrees are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(degree)
    degree.name_dw
  end
end
