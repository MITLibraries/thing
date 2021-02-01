class RemoveUserIdFromThesis < ActiveRecord::Migration[6.0]
  def change
    remove_column :theses, :user_id, :integer
  end
end
