# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100225231310) do

  create_table "accounts", :force => true do |t|
    t.string   "username"
    t.string   "password"
    t.string   "roomURL"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "accountname"
  end

  create_table "collectionnodes", :force => true do |t|
    t.string   "sharedID"
    t.integer  "nodes_id"
    t.integer  "userroles_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "room_id"
  end

  create_table "items", :force => true do |t|
    t.string   "associatedUserID"
    t.string   "body"
    t.string   "collectionName"
    t.string   "itemID"
    t.string   "nodeName"
    t.string   "publisherID"
    t.string   "recipientID"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_id"
  end

  create_table "nodeconfigurations", :force => true do |t|
    t.integer  "accessModel"
    t.boolean  "allowPrivateMessage"
    t.integer  "itemStorageSchem"
    t.boolean  "modifyAnyItem"
    t.boolean  "persistItems"
    t.integer  "publishModel"
    t.boolean  "sessionDependentItems"
    t.boolean  "userDependentItems"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_id"
  end

  create_table "nodes", :force => true do |t|
    t.string   "name"
    t.integer  "nodeconfiguration_id"
    t.integer  "items_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "collectionnode_id"
  end

  create_table "rooms", :force => true do |t|
    t.string   "roomURL"
    t.string   "roomName"
    t.integer  "roomTimeOut"
    t.integer  "roomUserLimit"
    t.string   "selectedBandwidth"
    t.boolean  "autoPromote"
    t.string   "endMeetingMessage"
    t.string   "webhookurl"
    t.boolean  "guestsHaveToKnock"
    t.boolean  "guestsNotAllowed"
    t.string   "productName"
    t.string   "roomLocked"
    t.string   "roomState"
    t.integer  "roomsetting_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roomsettings", :force => true do |t|
    t.boolean  "autoPromote"
    t.boolean  "guestMustKnock"
    t.string   "roomBandwidth"
    t.string   "roomState"
    t.string   "room_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "userroles", :force => true do |t|
    t.string   "userID"
    t.integer  "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "displayName"
    t.integer  "role"
    t.string   "userID"
    t.integer  "affiliation"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "userconnection"
    t.float    "starttime"
    t.integer  "room_id"
  end

  add_index "users", ["room_id"], :name => "fk_users_rooms"

end
