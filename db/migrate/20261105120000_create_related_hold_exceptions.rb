class CreateRelatedHoldExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :related_hold_exceptions do |table|
      table.references :thesis, null: false, index: false, foreign_key: true
      table.references :related_thesis, null: false, foreign_key: { to_table: :theses }
      table.timestamps
    end

    add_index :related_hold_exceptions, %i[thesis_id related_thesis_id], unique: true,
                                                                         name: 'index_related_hold_exceptions_on_pair'
    add_check_constraint :related_hold_exceptions, 'thesis_id <> related_thesis_id',
                         name: 'related_hold_exceptions_not_self'
  end
end
