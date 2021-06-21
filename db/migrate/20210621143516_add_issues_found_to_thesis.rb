class AddIssuesFoundToThesis < ActiveRecord::Migration[6.0]
  def change
    add_column :theses, :issues_found, :boolean, null: false, default: false
  end
end
