# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_RubyDevConsole_session',
  :secret      => 'cd1d82bfe619aa45288ba464319d6248fdbd40dd634a415c61406609275c6e333226f204040d59f171be635e0d6d8e78806675fec9a249a3ebc71e8952b79b68'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
