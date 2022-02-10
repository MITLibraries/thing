require 'administrate/base_dashboard'

class SubmissionInformationPackageDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    thesis: Field::BelongsTo,
    bag: AttachmentField,
    id: Field::Number,
    preserved_at: Field::DateTime,
    preservation_status: Field::Select.with_options(
      searchable: false,
      collection: lambda { |field|
                    field.resource.class.send(field.attribute.to_s.pluralize).keys
                  }
    ),
    bag_declaration: Field::String,
    bag_name: Field::String,
    manifest: Field::Text,
    metadata: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    bag_name
    preservation_status
    preserved_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    thesis
    bag
    id
    preserved_at
    preservation_status
    bag_declaration
    bag_name
    manifest
    metadata
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    thesis
    preserved_at
    preservation_status
    bag_declaration
    bag_name
    manifest
    metadata
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how submission information packages are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(submission_information_package)
  #   "SubmissionInformationPackage ##{submission_information_package.id}"
  # end
end
