class CreateRights < ActiveRecord::Migration[5.1]
  def change
    create_table :rights do |t|
      t.text :statement, null: false

      t.timestamps
    end
  end
end
