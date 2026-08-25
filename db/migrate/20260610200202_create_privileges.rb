class CreatePrivileges < ActiveRecord::Migration[8.1]
  def change
    create_table :privileges do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :name,       null: false
      t.integer    :point_cost, null: false, default: 0
      t.boolean    :active,     null: false, default: true

      t.timestamps
    end
  end
end
