class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :associatedUserID
      t.string :body
      t.string :collectionName
      t.string :itemID
      t.string :nodeName
      t.string :publisherID
      t.string :recipientID
      t.timestamps :timeStamp

      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
