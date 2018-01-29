class AddStatusToTheses < ActiveRecord::Migration[5.1]
  def change
    add_column :theses, :status, :string, default: 'active'
  end
end
