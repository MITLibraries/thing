class CreateTheses < ActiveRecord::Migration[5.1]
  def change
    create_table :theses do |t|
      t.string :title, null: false
      t.text :abstract, null: false
      t.date :grad_date, null: false

      t.timestamps
    end
  end
end
