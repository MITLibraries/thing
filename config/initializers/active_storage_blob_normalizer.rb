ActiveSupport.on_load(:active_storage_blob) do
  before_validation :normalize_filename, if: :will_save_change_to_filename?

  private

  def normalize_filename
    return if self[:filename].nil?

    self.filename = FilenameNormalizer.sanitize_filename(self[:filename])
  end
end
