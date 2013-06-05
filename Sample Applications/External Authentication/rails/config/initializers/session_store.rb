# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cocorail_session',
  :secret      => 'f2db307a203c374fb4bec1094630517e39f605c4935b483478947d5018dbb8df5ed36f5e53cb2d26dc1d4259d8b878fb3b9819b455cb91e6cd01e0a8680c7140'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
