class UpdateUserColumnConnectionToUserconnection < ActiveRecord::Migration
  def self.up
    remove_column :users, :connection
    add_column :users, :userconnection, :string
  end

  def self.down
    remove_column :users, :userconnection
  end
end
