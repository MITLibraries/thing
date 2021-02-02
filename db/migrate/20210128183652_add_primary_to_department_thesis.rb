class AddPrimaryToDepartmentThesis < ActiveRecord::Migration[6.0]
  def change
    add_column :department_theses, :id, :primary_key
    add_column :department_theses, :primary, :boolean, null: false, default: false
  end

  add_index :department_theses, [:department_id, :thesis_id], unique: true, name: "department_and_thesis"
end
