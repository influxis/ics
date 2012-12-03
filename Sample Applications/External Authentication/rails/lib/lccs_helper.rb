require 'lccs'

#
# A set of methods to simplify the use of LCCS
#
# A better implementation would cache the authenticated AccountManager
# to avoid unnecessary requests to the service
#
# = Copyright
#
#   ADOBE SYSTEMS INCORPORATED
#     Copyright 2007 Adobe Systems Incorporated
#     All Rights Reserved.
#
#   NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
#   terms of the Adobe license agreement accompanying it.  If you have received this file from a 
#   source other than Adobe, then your use, modification, or distribution of it requires the prior 
#   written permission of Adobe.
#

class RTCHelper

  #
  # update these constants with real account information
  #
  RTC_ACCOUNT = "http://connectnow.acrobat.com/<YOURACCOUNT>"
  RTC_SECRET = "<YOURSHAREDSECRET>"
  RTC_LOGIN = "<YOUREMAIL>"
  RTC_PASSWORD = "<YOURPASSWORD>"

  #
  # create a room
  #
  def self.createRoom(room)
    am = RTC::AccountManager.new(RTC_ACCOUNT)
    am.login(RTC_LOGIN, RTC_PASSWORD)
    am.createRoom(room)
  end

  #
  # delete a room
  #
  def self.deleteRoom(room)
    am = RTC::AccountManager.new(RTC_ACCOUNT)
    am.login(RTC_LOGIN, RTC_PASSWORD)
    am.deleteRoom(room)
  end

  #
  # get full URL for room
  #
  def self.getRoomURL(room)
    "#{RTC_ACCOUNT}/#{room}"
  end

  #
  # get authentication token
  #
  # note that in this implementation unnamed guests enter as "guest"
  #
  def self.getAuthToken(room, user)
    if user
      am = RTC::AccountManager.new(RTC_ACCOUNT)
      am.login(RTC_LOGIN, RTC_PASSWORD)

      session = am.getSession(room)
      role = if user.room_name == room; 100 else 10 end
      return session.getAuthenticationToken(RTC_SECRET, user.login, user.id, role)
    else
      return RTC::Authenticator.guestLogin("guest")
    end
  end
end
