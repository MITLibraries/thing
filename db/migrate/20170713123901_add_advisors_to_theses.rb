class AddAdvisorsToTheses < ActiveRecord::Migration[5.1]
  def change
    create_table :theses_advisors, id: false do |t|
      t.belongs_to :thesis, index: true
      t.belongs_to :advisor, index: true
    end
  end
end
