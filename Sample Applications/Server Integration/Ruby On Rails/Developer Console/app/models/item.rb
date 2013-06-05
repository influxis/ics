class Item < ActiveRecord::Base
  belongs_to :node

  def self.find_by_itemId_and_node_id(itemId, nodeId)
    myItems = Item.find_all_by_itemID(itemId)

    myItems.each { |item|
        if !item.nil? and item.node_id == nodeId.to_i
          return item
        end
    }

    return nil
  end

  def self.find_by_roomname_shareId_nodename_itemId(roomName, collectionName, nodename, itemId)
    myItems = Item.find_all_by_itemID(itemId)

    myItems.each { |item|
      node = Node.find_by_id(item.node_id)
      if !node.nil? and node.name == nodename
        collectionnode = Collectionnode.find_by_sharedID(collectionName)
        if !collectionnode.nil?
          room = Room.find_by_id(collectionnode.room_id)
          if !room.nil? and room.roomName == roomName
            return item
          end
        end
      end
    }

    return nil
  end

  def destroy

  end
end
