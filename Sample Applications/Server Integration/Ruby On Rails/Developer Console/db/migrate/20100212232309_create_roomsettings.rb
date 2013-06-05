class CreateRoomsettings < ActiveRecord::Migration
  def self.up
    create_table :roomsettings do |t|
      t.boolean :autoPromote
      t.boolean :guestMustKnock
      t.string :roomBandwidth
      t.string :roomState
      t.string :room_id

      t.timestamps
    end
  end

  def self.down
    drop_table :roomsettings
  end
end
