class CreateCopyrights < ActiveRecord::Migration[6.0]
  def change
    create_table :copyrights do |t|
      t.text :holder, null: false
      t.boolean :display_to_author, null: false
      t.text :display_description, null: false
      t.text :statement_dspace, null: false
      t.text :url, null: true

      t.timestamps
    end

    add_reference :theses, :copyright, null: true, index: true
  end
end
