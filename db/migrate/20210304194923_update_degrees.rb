class UpdateDegrees < ActiveRecord::Migration[6.0]
  def change
    create_table :degree_types do |t|
      t.string :name

      t.timestamps
    end

    change_table :degrees do |t|
      t.string :code_dw
      t.string :name_dw
      t.string :abbreviation
      t.string :name_dspace
      t.integer :degree_type_id
    end

    remove_column :degrees, :name, :string
    add_foreign_key :degrees, :degree_types
  end
end
