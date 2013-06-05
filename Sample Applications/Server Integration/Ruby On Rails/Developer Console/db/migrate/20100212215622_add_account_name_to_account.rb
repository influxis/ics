class AddAccountNameToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :accountname, :string
  end

  def self.down
    remove_column :accounts, :accountname
  end
end
