class AddDegreePeriodToArchivematicaAccessions < ActiveRecord::Migration[7.0]
  def change
    add_reference :archivematica_accessions, :degree_period, null: false, index: { unique: true }, foreign_key: true
  end
end
