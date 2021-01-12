class CreateHolds < ActiveRecord::Migration[6.0]
  def change
    create_table :hold_sources do |t|
      t.text :source, null: false

      t.timestamps
    end

    create_table :holds do |t|
      t.belongs_to :thesis, null: false, foreign_key: true
      t.date :date_requested, null: false
      t.date :date_start, null: false
      t.date :date_end, null: false
      t.belongs_to :hold_source, null: false, foreign_key: true
      t.string :case_number, null: true
      t.integer :status, null: false
      t.text :processing_notes, null: true

      t.timestamps
    end
  end
end
