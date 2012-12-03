class RTCHOOKSController < ApplicationController
   def receiveCollection
    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  def receiveNodes
    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  #/**
  #* Called any time createNode is triggered on a collectionNode
  #* which has been subscribed to.
  #* nodeConfigurationVO is a simple(POJO-like) representation of
  #* a nodeConfiguration, which can be deserialized via
  #* NodeConfiguration.readValueObject();
  #*/
  def receiveNode
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    nodeName = params[:nodeName]
    config=params[:nodeConfiguration]

    RTCHOOKSController.storeNode(roomName, collectionName, nodeName, config)

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  #/**
  #* Called any time removeNode is triggered on a collectionNode
  #* which has been subscribed to.
  #*/
  #
  def receiveNodeDeletion
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    nodeName = params[:nodeName]

    room = Room.find_by_roomName(roomName)

    if room.nil?
     return
    end

    collectionnode = Collectionnode.find_by_sharedID_and_room_id(collectionName, room.id)

    if(collectionnode.nil?)
     return
    end

    node = Node.find_by_nodename_and_collectionnod_id(nodeName, collectionnode.id)

    if(node.nil?)
      return
    end

    node.delete

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  def receiveItems
    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  # Called any time publishItem is triggered on a collectionNode
  # which has been subscribed to.
  # Note that ALL MESSAGES, whether private or not,
  # are sent to server listeners.
  # messageItemVO is a simple (POJO-like) representation of a messageItem,
  # which can be deserialized via MessageItem.readValueObject();
  def receiveItem
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    item= params[:item]

    RTCHOOKSController.storeItem(roomName, collectionName, item)

    mystring = token + " " + roomName + " " + collectionName + " " + item.to_xml

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

   #
   #retracts the given item from the service
   #
  def receiveItemRetraction
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    nodeName = params[:nodeName]
    item= params[:item]
    itemid = item["itemID"]

    myItem = Item.find_by_roomname_shareId_nodename_itemId(roomName, collectionName, nodeName, itemid)

    if !myItem.nil?

      if collectionName=="UserManager" and item["nodeName"]=="UserList"
        user = User.find_by_item_id(myItem.id)
        user.delete if user
      end

      myItem.delete
    end

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

  #
  #  Called any time setUserRole is triggered on a collectionNode
  #  which has been subscribed to.
  #
  def receiveUserRole
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    nodeName = params[:nodeName]
    userID = params[:userID]
    role = params[:role]

    room = Room.find_by_roomName(roomName)

    if !room.nil?
      user = User.find_by_userId_and_room_id(userID, room.id)
      if !user.nil?
        attributes = Hash.new(:role=>role.to_i, :userID => userID)
        user.update(user.id, attributes)
        user.save!
      end
    end

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

 #
  #/**
  #* Called any time setNodeConfiguration is triggered on a collectionNode which
  #* has been subscribed to.
  #* nodeConfigurationVO is a simple(POJO-like) representation of a
  #* nodeConfiguration, which can be deserialized via
  #* NodeConfiguration.readValueObject();
  #*/
  def receiveNodeConfiguration
    token = params[:token]
    roomName= params[:roomName]
    collectionName= params[:collectionName]
    nodeName = params[:nodeName]
    config=params[:nodeConfiguration]

    RTCHOOKSController.storeNode(roomName, collectionName, nodeName, config)

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end


  #
  #Use to store item in DB
  #
  def self.storeItem(roomName, collectionName, item)
    room = Room.find_by_roomName(roomName)

    if room.nil?
      room = Room.new(:roomName=>roomName)
      room.save!
    end

    collectionnode = Collectionnode.find_by_sharedID_and_room_id(collectionName, room.id)

    if(collectionnode.nil?)
      collectionnode=room.collectionnodes.create(:sharedID=>collectionName)
      collectionnode.save!
    end

    node = Node.find_by_nodename_and_collectionnod_id(item["nodeName"], collectionnode.id)

    if(node.nil?)
      node = collectionnode.nodes.create(:name=>item["nodeName"])
      node.save!
    end

    myItem = Item.find_by_itemId_and_node_id(item["itemID"], node.id)

    if (!myItem.nil?)
      myItem.update_attributes(:itemID=>item["itemID"], :associatedUserID=>item["associatedUserID"],
      :collectionName=>collectionName, :nodeName=>item["nodeName"], :body=>item["body"].to_json,
      :publisherID=>item["publisherID"],:recipientID=>item["recipientID"], :node_id=>node.id)
    else
      myItem = node.items.create(:itemID=>item["itemID"], :associatedUserID=>item["associatedUserID"],
      :collectionName=>collectionName, :nodeName=>item["nodeName"], :body=>item["body"].to_json,
      :publisherID=>item["publisherID"],:recipientID=>item["recipientID"], :node_id=>node.id)
    end

    myItem.save! if myItem

    if(!myItem.nil? and collectionName=="UserManager" and item["nodeName"]=="UserList")
      user = User.find_by_item_id(myItem.id)

      if !user.nil?
        attributes = Hash.new(:displayName=>item["body"]["displayName"], :userconnection=>item["body"]["connection"],
                      :role=>item["body"]["role"].to_i, :userID => item["body"]["userID"],
                      :affiliation => item["body"]["affiliation"], :starttime=>item["timeStamp"].to_d, :item_id=>myItem.id, :room_id=>room.id)
        user.update(user.id, attributes)

        user.save! if user

      else
         newuser = User.new(:displayName=>item["body"]["displayName"], :userconnection=>item["body"]["connection"],
                      :role=>item["body"]["role"].to_i, :userID => item["body"]["userID"],
                      :affiliation => item["body"]["affiliation"], :starttime=>item["timeStamp"].to_d, :item_id=>myItem.id, :room_id=>room.id)

        newuser.save! if newuser
      end


    end


  end


  def self.storeNode(roomName, collectionName, nodeName, config)
    room = Room.find_by_roomName(roomName)

    if room.nil?
      room = Room.new(:roomName=>roomName)
      room.save!
    end

    collectionnode = Collectionnode.find_by_sharedID_and_room_id(collectionName, room.id)

    if(collectionnode.nil?)
      collectionnode=room.collectionnodes.create(:sharedID=>collectionName)
      collectionnode.save!
    end

    node = Node.find_by_nodename_and_collectionnod_id(nodeName, collectionnode.id)

    if(node.nil?)
      node = collectionnode.nodes.create(:name=>nodeName)
      node.save!
    end

    myNodeConfig = Nodeconfiguration.find_by_node_id(node.id)

    if (!myNodeConfig.nil?)
      myNodeConfig.update_attributes(:accessModel=>config["accessModel"], :allowPrivateMessage=>config["allowPrivateMessage"],
      :itemStorageSchem=>config["itemStorageSchem"], :modifyAnyItem=>config["modifyAnyItem"], :persistItems=>config["persistItems"],
      :publishModel=>config["publishModel"],:sessionDependentItems=>config["sessionDependentItems"], :userDependentItems=>config["userDependentItems"])
    else
      myNodeConfig = Nodeconfiguration.create(:accessModel=>config["accessModel"], :allowPrivateMessage=>config["allowPrivateMessage"],
      :itemStorageSchem=>config["itemStorageSchem"], :modifyAnyItem=>config["modifyAnyItem"], :persistItems=>config["persistItems"],
      :publishModel=>config["publishModel"],:sessionDependentItems=>config["sessionDependentItems"], :userDependentItems=>config["userDependentItems"], :node_id=>node.id)
    end

    myNodeConfig.save!
  end
end
