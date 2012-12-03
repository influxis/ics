require 'lccs_helper'

class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])

    begin
      RTCHelper::createRoom(@user.room_name)
    rescue
      flash[:error] = "Cannot create room!"
      render :action => :new
      return
    end

    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      RTCHelper::deleteRoom(@user.room_name)
      flash[:error] = "Cannot create user!"
      render :action => :new
    end
  end
  
  def show
    @user = @current_user
  end
 
  def edit
    @user = @current_user
  end
  
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
