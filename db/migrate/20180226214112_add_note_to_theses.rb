class AddNoteToTheses < ActiveRecord::Migration[5.2]
  def change
    add_column :theses, :note, :text
  end
end
