/************************************************
* Adobe LCCS 2010-2011 
* Server To Server Ruby on Rails Interface and Example
* Version 1.0
* 
* This release aims at providing server to server integration with Adobe LCCS solution.
* Following instructions are targeting intermediate/experienced Ruby on Rail programmers.
* 
* This README file shows how to install Ruby AMF third party library that will allow LCCS server
* to invoke http hooks on your Ruby on Rail server and allowing your application to receive LCCS real time events 
* as Adobe Flash AMF packages.  It also demonstrate how your Ruby on Rails application invoking LCCS server APIs.   
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Invoking LCCS server APIs:

1) install RubyAMF via following instruction http://code.google.com/p/rubyamf/wiki/Installation.  
(e.g. ruby script/plugin install http://rubyamf.googlecode.com/svn/tags/current/rubyamf)

 
2) copy the lccs.rb to the <rootfolder>/lib directory.

3) create an instance of RTC::AccountManager and call login method.  Cache the object so only call login once.

4) you are ready to invoke LCCS APIs.
  
Setting Web Hooks:

1) best to use generate controller scafolding to create RTCHOOKS controller and copy paste the rtchooks_controller.rb code 
(this creates test file)

2) update rubyamf_config.rb with functional mappings

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



  #/**
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


3) Call RTC:AccountManager's registerHook and subscribeCollection with appropriate LCCS account information

4) You should be ready to receive messages.
