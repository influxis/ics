<cfcomponent>

    <!--- Set a CF session variable --->
    <cffunction name="receiveNode" access="remote" returnType="void">
        <cfargument name="token" type="string" required="yes">
        <cfargument name="roomName" type="string" required="yes">
        <cfargument name="collectionName" type="string" required="yes">
        <cfargument name="nodeName" type="string" required="yes">
        <cfargument name="config" type="any" required="yes">

	<cflog text = "receiveNode: #token#, #roomName#, #collectionName#, #nodeName#"
  log = "Application"
  file = "LCCS"
  thread = "yes"
  date = "yes"
  time = "yes"
  application = "yes"> 
    </cffunction>

    <!--- Set a CF session variable --->
    <cffunction name="receiveNodeDeletion" access="remote" returnType="void">
        <cfargument name="token" type="string" required="yes">
        <cfargument name="roomName" type="string" required="yes">
        <cfargument name="collectionName" type="string" required="yes">
        <cfargument name="nodeName" type="string" required="yes">

	<cflog text = "receiveNodeDeletion: #token#, #roomName#, #collectionName#, #nodeName#"
  log = "Application"
  file = "LCCS"
  thread = "yes"
  date = "yes"
  time = "yes"
  application = "yes"> 
    </cffunction>

    <!--- Set a CF session variable --->
    <cffunction name="receiveItem" access="remote" returnType="void">
        <cfargument name="token" type="string" required="yes">
        <cfargument name="roomName" type="string" required="yes">
        <cfargument name="collectionName" type="string" required="yes">
        <cfargument name="itemObj" type="any" required="yes">

	<cflog text = "receiveItem: #token#, #roomName#, #collectionName#, #itemObj.itemID#"
  log = "Application"
  file = "LCCS"
  thread = "yes"
  date = "yes"
  time = "yes"
  application = "yes"> 
    </cffunction>

    <!--- Set a CF session variable --->
    <cffunction name="receiveItemRetraction" access="remote" returnType="void">
        <cfargument name="token" type="string" required="yes">
        <cfargument name="roomName" type="string" required="yes">
        <cfargument name="collectionName" type="string" required="yes">
        <cfargument name="nodeName" type="string" required="yes">
        <cfargument name="itemObj" type="any" required="yes">

	<cflog text = "receiveItemRetraction: #token#, #roomName#, #collectionName#, #nodeName#"
  log = "Application"
  file = "LCCS"
  thread = "yes"
  date = "yes"
  time = "yes"
  application = "yes"> 
    </cffunction>

    <!--- Set a CF session variable --->
    <cffunction name="receiveNodeConfiguration" access="remote" returnType="void">
        <cfargument name="token" type="string" required="yes">
        <cfargument name="roomName" type="string" required="yes">
        <cfargument name="collectionName" type="string" required="yes">
        <cfargument name="nodeName" type="string" required="yes">
        <cfargument name="config" type="any" required="yes">

	<cflog text = "receiveNodeConfiguration: #token#, #roomName#, #collectionName#, #nodeName#"
  log = "Application"
  file = "LCCS"
  thread = "yes"
  date = "yes"
  time = "yes"
  application = "yes"> 
    </cffunction>


</cfcomponent>
