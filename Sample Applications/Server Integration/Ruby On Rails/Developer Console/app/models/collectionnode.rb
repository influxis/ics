class Collectionnode < ActiveRecord::Base
  has_many :nodes
  has_many :userroles
  belongs_to :room

   def self.find_by_sharedID_and_room_id(collectionName, roomId)
     collectionNodes = Collectionnode.find_all_by_sharedID(collectionName)
     collectionNodes.each { |cn|
        if cn.room_id == roomId.to_i
          return cn
        end
     }

     return nil

   end
end
