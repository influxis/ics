require "lccs"
require 'net/http'
require 'uri'

class RoomController < ApplicationController
  def roomManager
    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
    end

    @am = session[:am]
    acc = Account.find_by_username(session[:user_id])
    if(acc.nil?)
      flash[:notice] = "Need to login first"
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end

    @am.keepalive(acc.username, acc.password)

    @rooms = @am.list()

    @roominfos = Hash.new()

    @rooms.each { |room|
      @roominfos[room.name] = room.name
    }
  end

  def selectRoom
    roomName = params[:roomName]

    flash[:notice] = nil

    if !session[:user_id]
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
    end

    @am = session[:am]
    acc = Account.find_by_username(session[:user_id])
    if(acc.nil?)
      flash[:notice] = "Need to login first"
      session[:return_to_controller] = 'room'
      session[:return_to_action] = 'roomManager'
      redirect_to :controller=>'account', :action=> 'login'
      return
    end

    @roomName = roomName
    @roominfo = @am.getRoomInfo(roomName) if !roomName.nil?

    if(!@roominfo.nil? and @roominfo.isConnected == true)
      room = Room.find_by_roomName(roomName) if !roomName.nil?
      @users = User.find_all_by_room_id(room.id) if !room.nil?
    else
      flash[:notice] = roomName + " is disconnected."
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
