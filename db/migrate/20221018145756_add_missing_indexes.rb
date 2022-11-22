class AddMissingIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :active_storage_attachments, [:record_id, :record_type]
    add_index :active_storage_variant_records, :blob_id
    add_index :degrees, :degree_type_id
  end
end
