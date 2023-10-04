module Baggable
  # Before we try to bag anything, we need to check if it meets a few conditions. All published theses should have
  # at least one file attached, no duplicate filenames, a handle pointing to its DSpace record, and an accession number.
  def baggable_thesis?(thesis)
    return false unless thesis

    thesis.files.any? && thesis.dspace_handle.present? && unique_filenames?(thesis) && thesis.copyright.present? \
    && thesis.accession_number.present?
  end

  def unique_filenames?(thesis)
    !duplicate_filenames?(thesis)
  end

  def duplicate_filenames?(thesis)
    filenames = thesis.files.map { |f| f.filename.to_s }
    filenames.select { |f| filenames.count(f) > 1 }.uniq.any?
  end
end
