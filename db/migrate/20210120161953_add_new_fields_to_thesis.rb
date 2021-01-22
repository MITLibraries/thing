class AddNewFieldsToThesis < ActiveRecord::Migration[6.0]
  def change
    add_column :theses, :author_note, :text, null: true
    add_column :theses, :files_complete, :boolean, null: false, default: false
    add_column :theses, :metadata_complete, :boolean, null: false, default: false
    add_column :theses, :publication_status, :string, null: false, default: 'Not ready for publication'
  end
end
