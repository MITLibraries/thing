class RenameThesisNoteToProcessorNote < ActiveRecord::Migration[6.0]
  def change
    rename_column :theses, :note, :processor_note
  end
end
