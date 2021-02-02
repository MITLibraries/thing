# Ensures this module is included any time ActiveStorage class reloads
Rails.configuration.to_prepare do
  ActiveStorage::Attachment.include ActiveStorageAttachmentExtension
end
