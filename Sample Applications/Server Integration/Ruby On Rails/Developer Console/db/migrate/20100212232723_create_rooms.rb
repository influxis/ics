class CreateRooms < ActiveRecord::Migration
  def self.up
    create_table :rooms do |t|
      t.string :roomURL
      t.string :roomName
      t.integer :roomTimeOut
      t.integer :roomUserLimit
      t.string :selectedBandwidth
      t.boolean :autoPromote
      t.string :endMeetingMessage
      t.string :webhookurl
      t.boolean :guestsHaveToKnock
      t.boolean :guestsNotAllowed
      t.string :productName
      t.string :roomLocked
      t.string :roomState
      t.references :roomsetting

      t.timestamps
    end
  end

  def self.down
    drop_table :rooms
  end
end
