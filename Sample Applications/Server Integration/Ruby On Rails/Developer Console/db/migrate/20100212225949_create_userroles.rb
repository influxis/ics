class CreateUserroles < ActiveRecord::Migration
  def self.up
    create_table :userroles do |t|
      t.string :userID
      t.integer :role

      t.timestamps
    end
  end

  def self.down
    drop_table :userroles
  end
end
