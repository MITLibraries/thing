class ExtendActiveStorageForThesisTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :active_storage_attachments, :description, :text, null: true
    add_column :active_storage_attachments, :purpose, :integer, null: true
  end
end
