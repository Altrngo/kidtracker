class CreateChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :children do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :avatar_color
      t.integer :total_points

      t.timestamps
    end
  end
end
