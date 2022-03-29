class RemoveStatusFromThesis < ActiveRecord::Migration[6.1]
  def change
    remove_column :theses, :status, :string
  end
end
