class AddAuthorityKeyToDepartments < ActiveRecord::Migration[6.0]
  def change
    add_column :departments, :authority_key_dspace, :string
  end
end
