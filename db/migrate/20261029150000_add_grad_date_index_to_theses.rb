class AddGradDateIndexToTheses < ActiveRecord::Migration[8.1]
  # Allow concurrent index creation to avoid blocking normal writes while postgres builds the index
  disable_ddl_transaction!

  def change
    options = {}
    options[:algorithm] = :concurrently if connection.adapter_name == 'PostgreSQL'
    add_index :theses, :grad_date, **options
  end
end
