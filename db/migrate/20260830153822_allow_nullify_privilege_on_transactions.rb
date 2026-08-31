class AllowNullifyPrivilegeOnTransactions < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :point_transactions, :privileges
    add_foreign_key    :point_transactions, :privileges, on_delete: :nullify
  end

  def down
    remove_foreign_key :point_transactions, :privileges
    add_foreign_key    :point_transactions, :privileges
  end
end
