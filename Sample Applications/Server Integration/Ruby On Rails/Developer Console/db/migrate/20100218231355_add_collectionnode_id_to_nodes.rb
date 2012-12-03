class AddCollectionnodeIdToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :collectionnode_id, :integer
  end

  def self.down
    remove_column :nodes, :collectionnode_id
  end
end
