class User < ActiveRecord::Base
  belongs_to :room

  def self.find_by_userId_and_room_id(userId, room_id)
    myUsers = User.find_all_by_userID(userId)

    myUsers.each { |user|
        if !user.nil? and user.room_id == room_id.to_i
          return user
        end
    }

    return nil
  end
end
