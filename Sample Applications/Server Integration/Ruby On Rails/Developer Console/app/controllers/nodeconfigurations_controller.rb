class NodeconfigurationsController < ApplicationController
  # GET /nodeconfigurations
  # GET /nodeconfigurations.xml
  def index
    @nodeconfigurations = Nodeconfiguration.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nodeconfigurations }
    end
  end

  # GET /nodeconfigurations/1
  # GET /nodeconfigurations/1.xml
  def show
    @nodeconfiguration = Nodeconfiguration.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @nodeconfiguration }
    end
  end

  # GET /nodeconfigurations/new
  # GET /nodeconfigurations/new.xml
  def new
    @nodeconfiguration = Nodeconfiguration.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @nodeconfiguration }
    end
  end

  # GET /nodeconfigurations/1/edit
  def edit
    @nodeconfiguration = Nodeconfiguration.find(params[:id])
  end

  # POST /nodeconfigurations
  # POST /nodeconfigurations.xml
  def create
    @nodeconfiguration = Nodeconfiguration.new(params[:nodeconfiguration])

    respond_to do |format|
      if @nodeconfiguration.save
        flash[:notice] = 'Nodeconfiguration was successfully created.'
        format.html { redirect_to(@nodeconfiguration) }
        format.xml  { render :xml => @nodeconfiguration, :status => :created, :location => @nodeconfiguration }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @nodeconfiguration.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nodeconfigurations/1
  # PUT /nodeconfigurations/1.xml
  def update
    @nodeconfiguration = Nodeconfiguration.find(params[:id])

    respond_to do |format|
      if @nodeconfiguration.update_attributes(params[:nodeconfiguration])
        flash[:notice] = 'Nodeconfiguration was successfully updated.'
        format.html { redirect_to(@nodeconfiguration) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @nodeconfiguration.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /nodeconfigurations/1
  # DELETE /nodeconfigurations/1.xml
  def destroy
    @nodeconfiguration = Nodeconfiguration.find(params[:id])
    @nodeconfiguration.destroy

    respond_to do |format|
      format.html { redirect_to(nodeconfigurations_url) }
      format.xml  { head :ok }
    end
  end
end
