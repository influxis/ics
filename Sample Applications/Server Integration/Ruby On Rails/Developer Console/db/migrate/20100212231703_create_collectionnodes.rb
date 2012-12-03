class CreateCollectionnodes < ActiveRecord::Migration
  def self.up
    create_table :collectionnodes do |t|
      t.string :sharedID
      t.references :nodes
      t.references :userroles

      t.timestamps
    end
  end

  def self.down
    drop_table :collectionnodes
  end
end
