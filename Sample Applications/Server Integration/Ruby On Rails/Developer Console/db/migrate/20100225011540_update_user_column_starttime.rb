class UpdateUserColumnStarttime < ActiveRecord::Migration
  def self.up
    remove_column :users, :starttime
    add_column :users, :starttime, :double
  end

  def self.down
    remove_column :users, :starttime
  end
end
