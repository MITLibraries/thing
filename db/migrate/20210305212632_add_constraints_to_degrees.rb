class AddConstraintsToDegrees < ActiveRecord::Migration[6.0]
  def change
    # We need to define unique default values until these fields are 
    # used in the UI.
    Degree.find_each do |d|
      d.update(
        code_dw: "change_code" + Time.now.to_f.to_s
      )
    end
    DegreeType.find_each do |d|
      d.update(
        name: "change_name" + Time.now.to_f.to_s
      )
    end

    change_column_null :degrees, :code_dw, false
    change_column_null :degree_types, :name, false
    add_index :degrees, :code_dw, unique: true
    add_index :degree_types, :name, unique: true
  end
end
