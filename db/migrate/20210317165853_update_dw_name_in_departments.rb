class UpdateDwNameInDepartments < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        remove_index :departments, :name_dw
        add_index :departments, :name_dw
      end

      dir.down do
        remove_index :departments, :name_dw
        add_index :departments, :name_dw, unique: true
      end
    end
  end
end
