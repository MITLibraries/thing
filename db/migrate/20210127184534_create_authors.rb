class CreateAuthors < ActiveRecord::Migration[6.0]
  def change
    create_table :authors do |t|
      t.references :user, null: false, foreign_key: true
      t.references :thesis, null: false, foreign_key: true
      t.boolean :graduation_confirmed, null: false, default: false

      t.timestamps
    end
  end
end
