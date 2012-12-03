class UsersController < ApplicationController
  # GET /users
  # GET /users.xml
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])

    if !session[:user_id]
      flash[:notice] = "Need to login first"
      redirect_to :action=> 'login'
    end

    item = Item.find_by_id(@user.item_id)
    node = Node.find_by_id(item.node_id)
    collection = Collectionnode.find_by_id(node.collectionnode_id)
    room = Room.find_by_id(collection.room_id)
    roomname = room.roomName
    collectionname = collection.sharedID
    nodename = node.name
    itemid = item.itemID

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

      
    rescue Exception => msg
      flash[:notice] = msg
    end


    @user.destroy


    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end
