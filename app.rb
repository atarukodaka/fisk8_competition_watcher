require 'sinatra/base'
require 'sinatra/reloader'

require './update_database.rb'

class MyApp < Sinatra::Base
  register Sinatra::Reloader
  
  set :port, 1234
  set :bind, '0.0.0.0'
  set :database, {adapter: "pg", database: "db/competition_db"}

  enable :inline_templates
  include ERB::Util

  get '/' do
    "hello"
    dbmng = CompetitionWatcher::Database.new
    competitions = Competition.all
    competitions.map {|c|
      "<li>#{c[:key]} / #{c[:name]}"
    }.join("")
  end

  get '/competition' do
    key = params[:key]
    competition = Competition.find_by_key(key)
    "<li>name: #{competition[:name]}"
  end
  get '/entry' do
    key = params[:key]
    category = params[:category]

    dbmng = CompetitionWatcher::Database.new
    competition_id = Competition.find_by_key(key).id

    cond = {competition_id: competition_id}
    cond[:category] = category if category
    Entry.where(cond).map {|entry|
      skater_name = Skater.find_by_id(entry.skater_id).try(:name)
      "<li>[#{entry.category}] #{entry.number}: #{skater_name} (#{entry.skater_id})"
    }
  end
end
