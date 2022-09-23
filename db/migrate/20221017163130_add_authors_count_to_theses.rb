class AddAuthorsCountToTheses < ActiveRecord::Migration[6.1]
  def change
    add_column :theses, :authors_count, :integer
  end
end
