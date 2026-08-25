class CreateWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :weeks do |t|
      t.references :child,      null: false, foreign_key: true
      t.date       :start_date, null: false
      t.integer    :week_score, null: false, default: 0
      t.boolean    :finalized,  null: false, default: false

      t.timestamps
    end

    # Un enfant ne peut pas avoir deux semaines démarrant le même jour
    add_index :weeks, [ :child_id, :start_date ], unique: true
  end
end
