require 'sinatra/base'
require 'sinatra/reloader'

require './update_database.rb'

class MyApp < Sinatra::Base
  register Sinatra::Reloader
  
  set :port, 1234
  set :bind, '0.0.0.0'
#  set :database, {adapter: "postgresql", database: "hogehoge_db"}

  enable :inline_templates
  include ERB::Util

  get '/' do
    erb %Q[<li><a href="/list">competition list</a>]
  end

  get '/list' do
    dbmng = CompetitionWatcher::Database.new
    competitions = Competition.all.order("starting_date desc")
    erb competitions.map {|c|
      %Q[<li>#{c[:key]} / <a href="/competition?key=#{c[:key]}">#{c[:name]}</a>]
    }.join("")
  end

  get '/competition' do
    key = params[:key]
    competition = Competition.find_by_key(key)
    output = ["<h2>#{competition[:name]}</h2>"]
    output << %Q[<li><a href="/entry?key=#{competition[:key]}">entry</a>]
    erb output.join("")
  end
  get '/entry' do
    key = params[:key]
    category = params[:category]

    dbmng = CompetitionWatcher::Database.new
    competition_id = Competition.find_by_key(key).id

    cond = {competition_id: competition_id}
    cond[:category] = category if category
    erb Entry.where(cond).map {|entry|
      skater_name = Skater.find_by_id(entry.skater_id).try(:name)
      "<li>[#{entry.category}] #{entry.number}: #{skater_name} (#{entry.skater_id})"
    }.join("")
  end
end

__END__
@@layout
<html>
<head>
<title>Competition Watcher for figureskating</title>
</head>

<body>
  <h1>Competition Watcher for figureskating</h1>
  <%= yield %>
</body>
