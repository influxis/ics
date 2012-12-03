class RemoveForeignKeyFromUesrs < ActiveRecord::Migration
  def self.up
     execute "ALTER TABLE users DROP FOREIGN KEY fk_users_rooms"
  end

  def self.down
    execute <<-SQL
      ALTER TABLE users
        ADD CONSTRAINT fk_users_rooms
        FOREIGN KEY (room_id)
        REFERENCES rooms(id)
    SQL
  end
end
