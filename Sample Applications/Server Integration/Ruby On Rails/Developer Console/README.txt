/************************************************
* Adobe LCCS 2010
* Server To Server RubyOnRails Interface and Example
* Version 1.0
*
* The example shows how to use LCCS Server to Server API to invoke LCCS commands .  It also shows how to receive messages coming from LCCS room.
*
* following is the list of actions it can perform 
* 1) login  (e.g. http://<hostname>/account/login)
* 2) register hook 
* 3) subscribe collection 
* 4) Create Node
* 5) Remove Node
* 6) Publish Item
* 7) Retract Item
* 8) Set NodeConfiguration
* 9) Set User Role
* 10) Fetch Items
*
* You can also use this application to monitor LCCS rooms and users
* Once login you can 
* Show Current Rooms Under This Account (http://<hostname>/rooms) - CRUD operation minus Create and Update
* Show How many user under this room (http://localhost:8787/users) - CRUD operation minus Create and Update
* 
*
*
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Setup Procedure:

1)Create a new rails Project using the rails command [rails projectName].


2) Go to the project's root directory and install RubyAMF via following instruction http://code.google.com/p/rubyamf/wiki/Installation.  
 It can also installed via plugin [ruby script/plugin install http://rubyamf.googlecode.com/svn/tags/current/rubyamf]


3) Copy all the files in the DevConsole_RubyOnRails app, config, db and lib to the corresponding directories in your project.

WARNING: rtchooks_controller.rb has example code embedded, it is different from the rtchooks_controller.rb file under 
   the serverIntegration/ruby directory which is a more generic interface (do not use this copy, use the copy from the example directory)


4) update rubyamf_config.rb with functional mappings, this will allow rtchooks_controller to receive event method calls based on the argument name

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




5) To run example application, need to create db tables based on the schema and migrate to current version.

[rake db:create]
[rake db:migrate]

6) Start the server. /script/server

7) launch account login (http://<yoursever>/account/login), filled in LCCS account info and account url.  This will log you into accountmanager which allows you to call LCCS APIs.

 accountmanager has following operations:

   1. registerhook
   2. gethook info
   3. subscribecollection
   4. un-regiester hook
   5. unsubscribecollection
   6. createnode
   7. removenode
   8. publishItem
   9. retractItem
  10. set NodeConfiguration
  11. set User Role
  12. fetch Items


8)  use registerhook with hook url (e.g. http://<server>/rubyamf/gateway)

9) subscribe to your collection (subscribe to UserManager collection to get userlist in the room)

10) Login a user and you can click on "Show Current Rooms Under This Account" to show listing of rooms under account*( only when you subscribe to UserManager and when you receive events, this will create room db record.)




