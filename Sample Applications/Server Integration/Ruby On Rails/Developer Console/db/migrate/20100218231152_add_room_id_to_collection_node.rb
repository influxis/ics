class AddRoomIdToCollectionNode < ActiveRecord::Migration
  def self.up
    add_column :collectionnodes, :room_id, :integer
  end

  def self.down
    remove_column :collectionnodes, room_id
  end
end
