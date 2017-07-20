class AddThesisToUser < ActiveRecord::Migration[5.1]
  def change
    add_reference :theses, :user, index: true
  end
end
