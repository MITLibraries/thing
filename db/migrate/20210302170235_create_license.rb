class CreateLicense < ActiveRecord::Migration[6.0]
  def change
    create_table :licenses do |t|
      t.text :display_description, null: false
      t.text :license_type, null: false
      t.text :url, null: true

      t.timestamps
    end

    add_reference :theses, :license, null: true, index: true
  end
end
