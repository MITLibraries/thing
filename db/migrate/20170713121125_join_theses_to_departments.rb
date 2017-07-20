class JoinThesesToDepartments < ActiveRecord::Migration[5.1]
  def change
    create_table :departments_theses, id: false do |t|
      t.belongs_to :thesis, index: true
      t.belongs_to :department, index: true
    end
  end
end
