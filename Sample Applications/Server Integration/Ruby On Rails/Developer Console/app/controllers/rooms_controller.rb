class RoomsController < ApplicationController
  # GET /rooms
  # GET /rooms.xml
  def index
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @rooms = Room.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rooms }
    end
  end

  # GET /rooms/1
  # GET /rooms/1.xml
  def show
    
    @room = Room.find(params[:id])
    flash[:notice] = nil

    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end

    @am = session[:am]
    acc = Account.find_by_username(session[:user_id])
    if(acc.nil?)
      flash[:notice] = "Need to login first"
      session[:return_to_controller] = 'rooms'
      session[:return_to_action] = 'show'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end

    @roomName = @room.roomName
    @roominfo = @am.getRoomInfo(@room.roomName) if !@room.roomName.nil?

    if(!@roominfo.nil? and @roominfo.isConnected == true)
      room = Room.find_by_roomName(@room.roomName) if !@room.roomName.nil?
      @users = User.find_all_by_room_id(room.id) if !room.nil?
    else
      flash[:notice] = @room.roomName + " is disconnected."
    end

 
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @room }
    end
  end

  # GET /rooms/new
  # GET /rooms/new.xml
  def new
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @room = Room.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @room }
    end
  end

  # GET /rooms/1/edit
  def edit
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @room = Room.find(params[:id])
  end

  # POST /rooms
  # POST /rooms.xml
  def create
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @room = Room.new(params[:room])

    respond_to do |format|
      if @room.save
        flash[:notice] = 'Room was successfully created.'
        format.html { redirect_to(@room) }
        format.xml  { render :xml => @room, :status => :created, :location => @room }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @room.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /rooms/1
  # PUT /rooms/1.xml
  def update
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @room = Room.find(params[:id])

    respond_to do |format|
      if @room.update_attributes(params[:room])
        flash[:notice] = 'Room was successfully updated.'
        format.html { redirect_to(@room) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @room.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.xml
  def destroy
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end
    @room = Room.find(params[:id])
    @room.destroy

    respond_to do |format|
      format.html { redirect_to(rooms_url) }
      format.xml  { head :ok }
    end
  end

   def self.timedifffromnow(timedouble)
    t = Time.new
    diff = (t.to_f - timedouble/1000).round
    mytime_hr = diff/3600
    mytime_min = (diff%3600)/60
    mytime_sec = (diff%3600)%60
    return mytime_hr.to_s() + " hr " + mytime_min.to_s() + " min " + mytime_sec.to_s() + " sec "
  end
end
