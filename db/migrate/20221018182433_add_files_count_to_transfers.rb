class AddFilesCountToTransfers < ActiveRecord::Migration[6.1]
  def self.up
    add_column :transfers, :files_count, :integer, null: false, default: 0
    add_column :transfers, :unassigned_files_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :transfers, :files_count
  end
end
