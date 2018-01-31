class RenameDepartmentTheses < ActiveRecord::Migration[5.1]
  def change
    rename_table :departments_theses, :department_theses
  end
end
