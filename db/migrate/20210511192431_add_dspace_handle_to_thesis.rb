class AddDspaceHandleToThesis < ActiveRecord::Migration[6.0]
  def change
    add_column :theses, :dspace_handle, :string
  end
end
