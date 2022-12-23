class CreateProquestExportBatches < ActiveRecord::Migration[6.1]
  def change
    create_table :proquest_export_batches do |t|

      t.timestamps
    end

    add_reference :theses, :proquest_export_batch, null: true, index: true
  end
end
