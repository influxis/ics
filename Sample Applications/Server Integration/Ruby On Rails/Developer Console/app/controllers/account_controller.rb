require "lccs"

class AccountController < ApplicationController

  #authenticate user with lccs 
  def authenticate
    accountname = params[:userform]["accountname"]
    if(!accountname.nil?)
       @account = Account.find_by_accountname(accountname)
    end

    if(@account.nil?)
      @account = Account.new(params[:userform])
    else
      if(@account.roomURL != params[:userform]["roomURL"])
        @account.roomURL = params[:userform]["roomURL"]
        @account.username = params[:userform]["username"]
        @account.password =  params[:userform]["password"]
        @account.save!
      end
    end

    redirectvalue = params[:redirecturl]

    valid_user = false
    msg = "Invalid User/Password"
    if !@account.roomURL.nil? and !@account.username.nil? and !@account.password.nil? and !@account.accountname.nil?
      begin
        #flash[:notice] = "got here: " + @account.roomURL + " " + @account.username + " " + @account.password
        
       @am = RTC::AccountManager.new(@account.roomURL);
       token = @am.login(@account.username, @account.password);

        valid_user = true
      rescue Exception => msg
        valid_user = false
      end
    else
      msg = "null value " +  @account.roomURL + " " + @account.username + " " + @account.password + " " + @account.accountname
    end

    #if statement checks whether valid_user exists or not

    if valid_user
      #creates a session with username
      session[:user_id]= @account.username
      session[:token] = token
      session[:am] = @am

      @account.save

      if !session[:return_to_action].nil?
        redirect_to(:controller=>session[:return_to_controller], :action=>session[:return_to_action] )
        session[:return_to_action] = nil
        session[:return_to_controller] = nil
      elsif !redirectvalue.nil? and redirectvalue == 'roomManager'
          redirect_to :controller=>'room', :action=>'roomManager'
      else
        redirect_to :action => 'accountManager'
      end
      
    else
      flash[:notice] = "Login Failed: <br>" + msg
      redirect_to :action=> 'login'
    end

  end

  # login to the LCCS 
  # todo: need to verify connection status
  def login

  end

  def accountmanager
    if !session[:user_id]
      redirect_to :action=> 'login'
    end
  end

  def logout
    if session[:user_id]
      reset_session
    end

    redirect_to :action=> 'login'
  end

  #
  # Activates hooks notification for the account, and specifies a callbackURL
  # to use for receiving any such hooks.
  # securityToken can be used to specify a token to be passed back on each hook to identify
  # that the hook originated from LCCS.

  def registerHook
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    url = params[:registerhook]["url"]
    token = params[:registerhook]["token"]

    #redirect_to :controller=>"room", :action=> 'registerHook' #, :params[:registerHook].url => url, :params[:registerHook].token=>token
    
    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)
      result = am.registerHook(url, token)
      flash[:result] = "registerHook result success: " + result
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end
  end

  #
  #get hook information for the entire account
  #
  def getHookURL
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    #redirect_to :controller=>"room", :action=> 'registerHook' #, :params[:registerHook].url => url, :params[:registerHook].token=>token

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)
      result = am.getHookInfo()
      flash[:result] = "getHookInfo result success: " + result
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end
  end

  #
  #Remove hook notification for the entire account
  #
  def unregisterHook
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    #redirect_to :controller=>"room", :action=> 'registerHook' #, :params[:registerHook].url => url, :params[:registerHook].token=>token

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)
      result = am.unregisterHook()
      flash[:result] = "unregisterHook result success: " + result
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end
  end

  #
  #Activates notification for the given collection.
  #
  def subscribeCollection
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:subscribecollection]["roomname"]
    collectionnodename = params[:subscribecollection]["collectionnodename"]

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      result = am.subscribeCollection(roomname, collectionnodename)
      flash[:result] = "subscribeCollection result success: " + result
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end

  #
  #Removes notification for the given collection.
  #
  def unsubscribeCollection
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:unsubscribecollection]["roomname"]
    collectionnodename = params[:unsubscribecollection]["collectionnodename"]

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      result = am.unsubscribeCollection(roomname, collectionnodename)
      flash[:result] = "subscribeCollection result success: " + result
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end

  #
  #creates a new node at the specified location, optionally with a specified configuration.
  #
  def createNode
    if !session[:user_id] and !session[:am].nil?
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:createnode]["roomname"]
    collectionname = params[:createnode]["collectionname"]
    nodename = params[:createnode]["nodename"]

     #hash map key is CASE SENSITIVE
    configuration = Hash.new("configuration")
    configuration["persistItems"] = ((params[:createnode]["persistitems"]) == "true")? true:false
    configuration["userDependentItems"] = ((params[:createnode]["userdependentitems"]) == "true")? true:false
    configuration["publishModel"] = (params[:createnode]["publishmodel"]).to_i
    configuration["lazySubscription"] = ((params[:createnode]["lazysubscription"]) == "true")? true:false
    configuration["allowPrivateMessages"] = ((params[:createnode]["allowprivatemessages"]) == "true")? true:false
    configuration["modifyAnyItem"] =( (params[:createnode]["modifyanyitem"]) == "true")? true:false
    configuration["accessModel"] = (params[:createnode]["accessmodel"]).to_i
    configuration["itemStorageScheme"] = (params[:createnode]["itemstoragescheme"]).to_i
    configuration["sessionDependentItems"] = ((params[:createnode]["sessiondependentitems"]) == "true")? true:false
    configuration["p2pDataMessaging"] =((params[:createnode]["p2pdatamessaging"]) == "true")? true:false

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.createNode(roomname, collectionname, nodename, configuration)
        flash[:result] = "createNode result success: " + result +  " " + acc.roomURL + " " + collectionname + " " + nodename
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end

  #
  #removes the specified node.
  #Omitting the nodeName parameter removes the entire collection.
  #
  def removeNode
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:removenode]["roomname"]
    collectionname = params[:removenode]["collectionname"]
    nodename = params[:removenode]["nodename"]

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.removeNode(roomname, collectionname, nodename)
        flash[:result] = "removeNode result success: " + result +  " " + acc.roomURL + " " + collectionname + " " + nodename
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end

  #
  #publishes an item at the collection / node specified.
  #Note that publisherID allows the server to publish the item as the publisher specified.
  #
  def publishItem
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:publishitem]["roomname"]
    collectionname = params[:publishitem]["collectionname"]
    nodename = params[:publishitem]["nodename"]
    publisherid = params[:publishitem]["publisherid"]
    overwrite = (params[:publishitem]["overwrite"] == "true") ? true:false
    body = params[:publishitem]["itembodymsg"]

    item = Hash.new("item")
    item["publisherID"] = publisherid
    item["body"] = Hash.new("body")
    item["body"]["msg"] = body

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.publishItem(roomname, collectionname, nodename, item, overwrite)
        flash[:result] = "publishItem result success: " + result +  " " + acc.roomURL + " " + collectionname + " " + nodename + " "
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end

      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end


  #
  #retracts the given item from the service.
  #
  
  def retractItem
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:retractitem]["roomname"]
    collectionname = params[:retractitem]["collectionname"]
    nodename = params[:retractitem]["nodename"]
    itemid = params[:retractitem]["itemid"]

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.retractItem(roomname, collectionname, nodename, itemid)
        flash[:result] = "retractItem result success: " + result +  " " + acc.roomURL + " " + collectionname + " " + nodename + " " + itemid
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end
     
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end


  #
  #configures the specified node.
  #

  def setNodeConfiguration
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:setnodeconfiguration]["roomname"]
    collectionname = params[:setnodeconfiguration]["collectionname"]
    nodename = params[:setnodeconfiguration]["nodename"]

    #hash map key is CASE SENSITIVE
    configuration = Hash.new("configuration")
    configuration["persistItems"] = ((params[:setnodeconfiguration]["persistitems"]) == "true")? true:false
    configuration["userDependentItems"] = ((params[:setnodeconfiguration]["userdependentitems"]) == "true")? true:false
    configuration["publishModel"] = (params[:setnodeconfiguration]["publishmodel"]).to_i
    configuration["lazySubscription"] = ((params[:setnodeconfiguration]["lazysubscription"]) == "true")? true:false
    configuration["allowPrivateMessages"] = ((params[:setnodeconfiguration]["allowprivatemessages"]) == "true")? true:false
    configuration["modifyAnyItem"] =( (params[:setnodeconfiguration]["modifyanyitem"]) == "true")? true:false
    configuration["accessModel"] = (params[:setnodeconfiguration]["accessmodel"]).to_i
    configuration["itemStorageScheme"] = (params[:setnodeconfiguration]["itemstoragescheme"]).to_i
    configuration["sessionDependentItems"] = ((params[:setnodeconfiguration]["sessiondependentitems"]) == "true")? true:false
    configuration["p2pDataMessaging"] =((params[:setnodeconfiguration]["p2pdatamessaging"]) == "true")? true:false

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.setNodeConfiguration(roomname, collectionname, nodename, configuration)
        flash[:result] = "setNodeConfiguration result success: " + result +  " " + acc.roomURL + " " + collectionname + " " + nodename
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end
      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end


  #
  #sets the role of the given user, either on the room as a whole
  #(if collectionName and nodeName are omitted),
  #or on a particular collection or node.
  #

  def setUserRole
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:setuserrole]["roomname"]
    collectionname = (params[:setuserrole]["collectionname"].length ==0)? nil:params[:setuserrole]["collectionname"]
    nodename = (params[:setuserrole]["nodename"].length==0)? nil:params[:setuserrole]["nodename"]
    userid = params[:setuserrole]["userid"]
    role = params[:setuserrole]["role"]

    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.setUserRole(roomname, userid, role, collectionname, nodename)
        flash[:result] = "setUserRole result success: " + result +  " " + acc.roomURL + " " + userid + " " + role
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end

      redirect_to :action => 'accountManager'
    rescue Exception => msg
      flash[:notice] = msg
    end

  end

  #/**
  #* Returns an array of MessageItems, corresponding to the items specified
  #* on the given node.
  #* Any itemIDs not found on the service are simply ignored.
  #* Omitting the itemIDs array will return the full list of items in the node.
  #*/
  def fetchItems
    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    roomname = params[:fetchItems]["roomname"]
    collectionname = params[:fetchItems]["collectionname"]
    nodename = params[:fetchItems]["nodename"]
    itemids_str = params[:fetchItems]["items"]

    items = nil

    if(!itemids_str.nil? and itemids_str.length > 0)
      begin
        items = itemids_str.split(/,/)
        items.each { |item|
          item.strip!
        }
      rescue
        items = nil
      end
    end
      
    
    begin
      am = session[:am]
      acc = Account.find_by_username(session[:user_id])
      if(acc.nil?)
        flash[:notice] = "Need to login first"
        redirect_to :action=> 'login'
        return
      end
      am.keepalive(acc.username, acc.password)

      myroominfo = am.getRoomInfo(roomname)
      if(!myroominfo.nil? and myroominfo.isConnected == true)
        result = am.fetchItems(roomname, collectionname, nodename, items)

        if !result.empty?
          result.each_pair do |k,item|
            RTCHOOKSController.storeItem(roomname, collectionname, item)
          end
          
          flash[:result] = "fetchItems result success: " + result.to_json +  " " + acc.roomURL + " " + nodename + " " + itemids_str

        else
          flash[:result] = "fetchItems result success: no items "  + acc.roomURL + " " + nodename + " " + itemids_str
        end
        
      else
        result = "Room is shutdown, this feature only available when room is started."
        flash[:notice] = result
      end

      redirect_to :action => 'accountManager'

    rescue Exception => msg
      flash[:notice] = msg
    end
  end


  
  def internal_redirect_to (options={})

    flash[:notice] = "internal_redirect_to"

    params.merge!(options)

    (c = ActionController.const_get(Inflector.classify("#{params[:controller]}_controller")).new).process(request,response)
    
    c.instance_variables.each{|v| self.instance_variable_set(v,c.instance_variable_get(v))}
  end

end
