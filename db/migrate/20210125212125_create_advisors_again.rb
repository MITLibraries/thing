class CreateAdvisorsAgain < ActiveRecord::Migration[6.0]
  def change
    create_table :advisors do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :advisor_theses, id: false do |t|
      t.belongs_to :thesis, index: true
      t.belongs_to :advisor, index: true
    end
  end
end
