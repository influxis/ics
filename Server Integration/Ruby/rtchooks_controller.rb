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

    respond_to do |format|
      format.amf { render :amf => true }
    end
  end

