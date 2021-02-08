class UpdateUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :kerberos_id, :string, null: false
    add_column :users, :display_name, :string, null: false
    add_column :users, :middle_name, :string, null: true
    add_column :users, :preferred_name, :string, null: true
    add_column :users, :orcid, :string, null: true
    
    add_index :users, :kerberos_id, unique: true
    add_index :users, :orcid, unique: true
  end
end
