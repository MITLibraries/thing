class CreateSubmitters < ActiveRecord::Migration[6.0]
  def change
    create_table :submitters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true

      t.timestamps
    end
  end
end
