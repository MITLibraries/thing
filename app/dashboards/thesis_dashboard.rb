require 'administrate/base_dashboard'

class ThesisDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  #
  # The dashboard must know about grad_date, since it is a column on the model
  # schema, but also about graduation_year and graduation_month, since Thesis
  # performs before_create validation on these objects.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    right: Field::BelongsTo,
    departments: Field::HasMany,
    degrees: Field::HasMany,
    id: Field::Number,
    title: Field::String,
    abstract: Field::Text,
    grad_date: Field::DateTime.with_options(
      format: "%Y %B"
    ),
    graduation_month: Field::Number,
    graduation_year: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    files: FileField,
    files_complete: Field::Boolean,
    status: Field::Select.with_options(
      collection: Thesis::STATUS_OPTIONS,
    ),
    publication_status: Field::Select.with_options(
      collection: Thesis::PUBLICATION_STATUS_OPTIONS,
    ),
    author_note: Field::Text,
    processor_note: Field::Text,
    metadata_complete: Field::Boolean,
    holds: Field::HasMany,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    title
    user
    holds
    right
    grad_date
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    title
    abstract
    grad_date
    right
    created_at
    updated_at
    departments
    degrees
    holds
    status
    publication_status
    author_note
    processor_note
    metadata_complete
    files_complete
    files
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  #
  # Make sure you display graduation_year and graduation_month on the form or
  # you will be unable to create Theses!
  FORM_ATTRIBUTES = %i[
    user
    right
    departments
    degrees
    title
    abstract
    status
    publication_status
    graduation_year
    graduation_month
    author_note
    processor_note
    metadata_complete
    files_complete
  ].freeze

  # Overwrite this method to customize how theses are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(thesis)
    "Thesis: #{thesis.title} (by #{thesis.user.name})"
  end
end
