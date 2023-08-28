class CreateArchivematicaAccessions < ActiveRecord::Migration[7.0]
  def change
    create_table :archivematica_accessions do |t|
      t.string :accession_number
      t.index :accession_number, unique: true

      t.timestamps
    end
  end
end
