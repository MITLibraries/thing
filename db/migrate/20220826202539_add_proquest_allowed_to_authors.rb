class AddProquestAllowedToAuthors < ActiveRecord::Migration[6.1]
  def change
    add_column :authors, :proquest_allowed, :boolean, null: true, default: nil
  end
end
