class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :username, :string

    User.reset_column_information
    User.find_each do |u|
      base = u.email.to_s.split("@").first.to_s.gsub(/[^a-zA-Z0-9_.\-]/, "")
      base = "user#{u.id}" if base.blank?
      name = base
      name = "#{base}#{u.id}" if User.where(username: name).where.not(id: u.id).exists?
      u.update_columns(username: name)
    end

    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end

  def down
    remove_index  :users, :username
    remove_column :users, :username
  end
end
