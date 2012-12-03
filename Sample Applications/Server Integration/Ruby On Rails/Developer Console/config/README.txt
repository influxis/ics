1) install AMFRuby from ...

2) best to use generate controller scafolding to create RTCHOOKS controller and copy paste the rtchooks_controller.rb code 
(this creates test file)

3) update rubyamf_config.rb with functional mapppings

ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveItem,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :item=>"[3]"})
                   
   #
   #retracts the given item from the service.
   #
   # void Session.retractItem(
   # String roomName,
   # String collectionName,
   # String nodeName,
   # String itemID);
   #
    ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveItemRetraction,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :nodeName=>"[3]",
                                        :item=>"[4]"})

  #
  #void receiveUserRole{
  # String securityToken,
  #String roomName,
  #String collectionName = null,
  #String nodeName = null,
  #String userID,
  #int p_role);
  #
  ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveUserRole,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :nodeName=>"[3]",
                                        :userID=>"[4]",
                                        :role=>"[5]"})


  #/**
  #* Called any time removeNode is triggered on a collectionNode
  #* which has been subscribed to.
  #*/
  #void receiveNodeDeletion(
  #  String securityToken,
  #  String roomName,
  #  String collectionName,
  #  String nodeName);
  #
  ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveNodeDeletion,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :nodeName=>"[3]"})



  #  /**
  #* Called any time createNode is triggered on a collectionNode
  #* which has been subscribed to.
  #* nodeConfigurationVO is a simple(POJO-like) representation of
  #* a nodeConfiguration, which can be deserialized via
  #* NodeConfiguration.readValueObject();
  #*/
  #void receiveNode(
  #  String securityToken,
  #  String roomName,
  #  String collectionName,
  #  String nodeName,
  #  Object nodeConfigurationVO);

  ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveNode,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :nodeName=>"[3]",
                                        :nodeConfiguration=>"[4]"})
  #
  #/**
  #* Called any time setNodeConfiguration is triggered on a collectionNode which
  #* has been subscribed to.
  #* nodeConfigurationVO is a simple(POJO-like) representation of a
  #* nodeConfiguration, which can be deserialized via
  #* NodeConfiguration.readValueObject();
  #*/
  #void receiveNodeConfiguration(
  #  String securityToken,
  #  String roomName,
  #  String collectionName,
  #  String nodeName,
  #  Object nodeConfigurationVO);

  ParameterMappings.register(:controller=> :RTCHOOKSController,
                                :action=> :receiveNodeConfiguration,
                                :params=>{:token=> "[0]",
                                        :roomName=>"[1]",
                                        :collectionName=>"[2]",
                                        :nodeName=>"[3]",
                                        :nodeConfiguration=>"[4]"})



4) to run example application, need to create db tables based on the schema and migrate to current version. 

5) copy the corresponding controller/model/viewer to the respective directories.
