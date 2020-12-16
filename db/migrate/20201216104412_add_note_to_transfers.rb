class AddNoteToTransfers < ActiveRecord::Migration[5.2]
  def change
    add_column :transfers, :note, :text
  end
end
