class AddDataToDepartments < ActiveRecord::Migration[6.0]
  def up
    rename_column :departments, :name, :name_dw
    add_column :departments, :code_dw, :string, null: false, default: ''
    add_column :departments, :name_dspace, :string, null: true

    # These values aren't used in the UI yet, so we define unique default
    # values for now. This could be done in two separate migrations to split
    # this up a bit more.
    Department.find_each do |d|
      d.update(
        code_dw: "change_code" + Time.now.to_f.to_s
      )
    end

    add_index :departments, :code_dw, unique: true
    add_index :departments, :name_dw, unique: true
  end

  def down
    remove_index :departments, :name_dw
    remove_index :departments, :code_dw

    remove_column :departments, :name_dspace
    rename_column :departments, :name_dw, :name
    remove_column :departments, :code_dw
  end
end
