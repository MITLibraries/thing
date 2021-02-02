# This is necessary for the enum (or for any model relationships we want to
# define). We can access the fields we want to extend directly with just the
# database migration, but this allows for the enum which should be convenient
# over time to ensure our data only contains states we are expecting.

module ActiveStorageAttachmentExtension
  extend ActiveSupport::Concern

  included do
    enum purpose: [:thesis_pdf, :thesis_source, :thesis_supplementary_file,
                   :proquest_form, :signature_page]
  end
end
