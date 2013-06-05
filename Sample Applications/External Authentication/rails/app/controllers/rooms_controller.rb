require 'lccs_helper'

class RoomsController < ApplicationController
  before_filter :require_user, :only => [:index]

  #
  # this page requires authentication and return info about the user and its room
  #
  def index
    @user = @current_user
  end

  #
  # this page doesn't require authentication
  #
  # if the user is logged in it will use the user's info,
  # otherwise it will assume a guest
  #
  def show
    if params[:id]
      current_user # initialize @current_user

      @room  = {
    	:name => params[:id],
    	:url => RTCHelper::getRoomURL(params[:id]),
    	:token => RTCHelper::getAuthToken(params[:id], @current_user)
      }
    else
      #
      # if there is no room, we really wanted to go to /rooms/index
      #
      redirect_to :action => 'index'
    end
  end
end
