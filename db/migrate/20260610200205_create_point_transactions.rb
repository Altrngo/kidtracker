class CreatePointTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :point_transactions do |t|
      t.references :child,     null: false, foreign_key: true
      # privilege peut être nil (ajustement manuel, finalisation de semaine)
      t.references :privilege, null: true,  foreign_key: true
      t.integer    :amount,    null: false
      t.string     :reason,    null: false

      t.timestamps
    end
  end
end
