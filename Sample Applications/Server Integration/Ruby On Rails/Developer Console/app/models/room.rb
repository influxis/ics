class Room < ActiveRecord::Base
  has_one :roomsetting
  has_many :collectionnodes
  has_many :users
end
