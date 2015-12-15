require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

local_db_address = "postgresql://postgres@192.168.33.10/competition_db"
db_address = ENV['DATABASE_URL'] || local_db_address
puts db_address
ActiveRecord::Base.establish_connection(db_address)

