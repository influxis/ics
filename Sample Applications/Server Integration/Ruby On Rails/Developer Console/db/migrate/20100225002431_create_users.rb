class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :displayName
      t.string :connection
      t.integer :role
      t.string :userID
      t.integer :affiliation
      t.timestamp :starttime
      t.references :item

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
