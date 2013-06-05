class Node < ActiveRecord::Base
  has_one :nodeconfiguration
  has_many :items
  belongs_to :collectionnode

  def self.find_by_nodename_and_collectionnod_id(nodeName, collectionId)
    nodes = Node.find_all_by_name(nodeName)
    nodes.each { |n|
        if n.collectionnode_id == collectionId.to_i
          return n
        end
     }

     return nil

   end
end
