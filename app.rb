require 'sinatra/base'
require 'sinatra/reloader'

require './competition_watcher'

module CompetitionWatcher
  class Application < Sinatra::Base
    register Sinatra::Reloader

    set :port, 1234
    set :bind, '0.0.0.0'

    enable :inline_templates
    include ERB::Util

    get '/' do
      erb %Q[<li><a href="/competitions">competition list</a>
  <li><a href="/skaters">skater list</a>]
    end

    get '/competitions' do
      dbmng = CompetitionWatcher::Database.new
      competitions = Competition.all.order("starting_date desc")

      erb competitions.map {|c|
        %Q[<li>#{c[:key]} / <a href="/competition?key=#{c[:key]}">#{c[:name]}</a>]
      }.join("")
      
      erb :competitions, locals: {competitions: competitions}
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

    get '/skaters' do
      dbmng = CompetitionWatcher::Database.new
      skaters = Skater.all.order("isu_number desc")
      erb "<h2>Skaters</h2>" + skaters.map {|s|
        %Q[<li>#{s[:name]} (#{s[:isu_number]})]
      }.join("")
    end

    get '/skater' do
    end
  end
end
