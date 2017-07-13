class JoinThesesToDepartments < ActiveRecord::Migration[5.1]
  def change
    create_table :theses_departments, id: false do |t|
      t.belongs_to :thesis, index: true
      t.belongs_to :department, index: true
    end
  end
end
