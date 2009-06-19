# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_symphony_requests_session',
  :secret      => '5c6ba661af687cb4c37af5071a7cabb5c4c0c158bec04d11bebedb39d657089cccf0817ef84bf9d6ea1fa6f2ab92da288a14e28aaa3181567e5a9f4f3e532461'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
