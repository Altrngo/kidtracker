class AddUserAndQuantityToPointTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :point_transactions, :user, null: true, foreign_key: true
    add_column    :point_transactions, :quantity, :integer, null: false, default: 1
  end
end
