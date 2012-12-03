class CreateNodeconfigurations < ActiveRecord::Migration
  def self.up
    create_table :nodeconfigurations do |t|
      t.integer :accessModel
      t.boolean :allowPrivateMessage
      t.integer :itemStorageSchem
      t.boolean :modifyAnyItem
      t.boolean :persistItems
      t.integer :publishModel
      t.boolean :sessionDependentItems
      t.boolean :userDependentItems

      t.timestamps
    end
  end

  def self.down
    drop_table :nodeconfigurations
  end
end
