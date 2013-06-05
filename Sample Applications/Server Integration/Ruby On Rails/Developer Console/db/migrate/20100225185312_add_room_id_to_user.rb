class AddRoomIdToUser < ActiveRecord::Migration
  def self.up
   add_column :users, :room_id, :integer
   
    #add a foreign key
    execute <<-SQL
      ALTER TABLE users
        ADD CONSTRAINT fk_users_rooms
        FOREIGN KEY (room_id)
        REFERENCES rooms(id)
    SQL

    
  end

  def self.down
    execute "ALTER TABLE users DROP FOREIGN KEY fk_users_rooms"
    remove_column :users, :room_id
  end
end
