class AddProquestExportedToThesis < ActiveRecord::Migration[6.1]
  def change
    add_column :theses, :proquest_exported, :integer, null: false, default: 0
  end
end
