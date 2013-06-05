class RoomsettingsController < ApplicationController
  # GET /roomsettings
  # GET /roomsettings.xml
  def index
    @roomsettings = Roomsetting.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roomsettings }
    end
  end

  # GET /roomsettings/1
  # GET /roomsettings/1.xml
  def show
    @roomsetting = Roomsetting.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @roomsetting }
    end
  end

  # GET /roomsettings/new
  # GET /roomsettings/new.xml
  def new
    @roomsetting = Roomsetting.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @roomsetting }
    end
  end

  # GET /roomsettings/1/edit
  def edit
    @roomsetting = Roomsetting.find(params[:id])
  end

  # POST /roomsettings
  # POST /roomsettings.xml
  def create
    @roomsetting = Roomsetting.new(params[:roomsetting])

    respond_to do |format|
      if @roomsetting.save
        flash[:notice] = 'Roomsetting was successfully created.'
        format.html { redirect_to(@roomsetting) }
        format.xml  { render :xml => @roomsetting, :status => :created, :location => @roomsetting }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @roomsetting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /roomsettings/1
  # PUT /roomsettings/1.xml
  def update
    @roomsetting = Roomsetting.find(params[:id])

    respond_to do |format|
      if @roomsetting.update_attributes(params[:roomsetting])
        flash[:notice] = 'Roomsetting was successfully updated.'
        format.html { redirect_to(@roomsetting) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @roomsetting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /roomsettings/1
  # DELETE /roomsettings/1.xml
  def destroy
    @roomsetting = Roomsetting.find(params[:id])
    @roomsetting.destroy

    respond_to do |format|
      format.html { redirect_to(roomsettings_url) }
      format.xml  { head :ok }
    end
  end
end
