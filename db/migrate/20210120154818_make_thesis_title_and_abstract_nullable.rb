class MakeThesisTitleAndAbstractNullable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :theses, :title, true
    change_column_null :theses, :abstract, true
  end
end
