class AddCoauthorsToThesis < ActiveRecord::Migration[6.0]
  def change
  	add_column :theses, :coauthors, :string, default: nil
  end
end
