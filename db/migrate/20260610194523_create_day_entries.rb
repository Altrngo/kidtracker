class CreateDayEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :day_entries do |t|
      t.references :week,       null: false, foreign_key: true
      t.references :child_item, null: false, foreign_key: true
      t.integer    :day_of_week, null: false  # 0=Lundi … 6=Dimanche
      t.string     :emoji_state, null: false, default: "green"
      t.integer    :computed_points, null: false, default: 0

      t.timestamps
    end

    # Une seule entrée par item par jour par semaine
    add_index :day_entries, [ :week_id, :child_item_id, :day_of_week ], unique: true
  end
end
