class AddNameFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :given_name, :string
    add_column :users, :surname, :string
  end
end
