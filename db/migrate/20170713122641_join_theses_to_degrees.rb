class JoinThesesToDegrees < ActiveRecord::Migration[5.1]
  def change
    create_table :degrees_theses, id: false do |t|
      t.belongs_to :thesis, index: true
      t.belongs_to :degree, index: true
    end
  end
end
