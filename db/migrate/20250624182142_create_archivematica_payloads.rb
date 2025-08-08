class CreateArchivematicaPayloads < ActiveRecord::Migration[7.1]
  def change
    create_table :archivematica_payloads do |t|
      t.integer :preservation_status, null: false, default: 0
      t.text :payload_json
      t.datetime :preserved_at

      t.references :thesis, null: false, foreign_key: true

      t.timestamps
    end
  end
end
