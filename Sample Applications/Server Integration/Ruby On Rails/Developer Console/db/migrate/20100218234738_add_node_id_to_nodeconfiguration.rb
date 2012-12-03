class AddNodeIdToNodeconfiguration < ActiveRecord::Migration
  def self.up
    add_column :nodeconfigurations, :node_id, :integer
  end

  def self.down
    remove_column :nodeconfigurations, :node_id
  end
end
