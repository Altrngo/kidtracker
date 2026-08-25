class CreateChildItems < ActiveRecord::Migration[8.1]
  def change
    create_table :child_items do |t|
      t.references :child, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :green_points
      t.integer :yellow_points
      t.integer :red_points
      t.boolean :active

      t.timestamps
    end
  end
end
