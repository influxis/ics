class CollectionnodesController < ApplicationController
  # GET /collectionnodes
  # GET /collectionnodes.xml
  def index
    @collectionnodes = Collectionnode.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @collectionnodes }
    end
  end

  # GET /collectionnodes/1
  # GET /collectionnodes/1.xml
  def show
    @collectionnode = Collectionnode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @collectionnode }
    end
  end

  # GET /collectionnodes/new
  # GET /collectionnodes/new.xml
  def new
    @collectionnode = Collectionnode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @collectionnode }
    end
  end

  # GET /collectionnodes/1/edit
  def edit
    @collectionnode = Collectionnode.find(params[:id])
  end

  # POST /collectionnodes
  # POST /collectionnodes.xml
  def create
    @collectionnode = Collectionnode.new(params[:collectionnode])

    respond_to do |format|
      if @collectionnode.save
        flash[:notice] = 'Collectionnode was successfully created.'
        format.html { redirect_to(@collectionnode) }
        format.xml  { render :xml => @collectionnode, :status => :created, :location => @collectionnode }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @collectionnode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /collectionnodes/1
  # PUT /collectionnodes/1.xml
  def update
    @collectionnode = Collectionnode.find(params[:id])

    respond_to do |format|
      if @collectionnode.update_attributes(params[:collectionnode])
        flash[:notice] = 'Collectionnode was successfully updated.'
        format.html { redirect_to(@collectionnode) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @collectionnode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /collectionnodes/1
  # DELETE /collectionnodes/1.xml
  def destroy
    @collectionnode = Collectionnode.find(params[:id])
    @collectionnode.destroy

    respond_to do |format|
      format.html { redirect_to(collectionnodes_url) }
      format.xml  { head :ok }
    end
  end
end
