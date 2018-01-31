class DegreeThesesRefactor < ActiveRecord::Migration[5.1]
  def change
    rename_table :degrees_theses, :degree_theses
  end
end
