class CreateSubmissionInformationPackage < ActiveRecord::Migration[6.1]
  def change
    create_table :submission_information_packages do |t|
      t.datetime :preserved_at
      t.integer :preservation_status, null: false, default: 0
      t.string :bag_declaration
      t.string :bag_name
      t.text :manifest
      t.text :metadata

      t.references :thesis, null: false, foreign_key: true

      t.timestamps
    end
  end
end
