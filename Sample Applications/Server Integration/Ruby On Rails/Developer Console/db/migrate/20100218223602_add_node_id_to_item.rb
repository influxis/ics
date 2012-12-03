class AddNodeIdToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :node_id, :integer
  end

  def self.down
    remove_column :items, :node_id
  end
end
