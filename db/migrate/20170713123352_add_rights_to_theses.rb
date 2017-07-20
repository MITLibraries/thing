class AddRightsToTheses < ActiveRecord::Migration[5.1]
  def change
    add_reference :theses, :right, index: true
  end
end
