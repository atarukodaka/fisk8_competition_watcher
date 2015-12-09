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

    def connect_database
      @database = CompetitionWatcher::Database.new if @database.nil?
    end

    get '/' do
      erb :home
    end

    get '/competitions' do
      connect_database()
      competitions = Competition.all.order("starting_date desc")

      erb competitions.map {|c|
        %Q[<li>#{c[:key]} / <a href="/competition?key=#{c[:key]}">#{c[:name]}</a>]
      }.join("")
      
      erb :competitions, locals: {competitions: competitions}
    end

    get '/competition' do
      connect_database()
      key = params[:key]
      competition = Competition.find_by_key(key)
      erb :competition, locals: {competition: competition}
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

    get '/result' do
      erb "not yet available"
    end
    get '/calendar' do
      connect_database()
      erb :calendar
    end
    ################################################################
    get '/skaters' do
      dbmng = CompetitionWatcher::Database.new
      skaters = Skater.all.order("isu_number desc")
      erb "<h2>Skaters</h2>" + skaters.map {|s|
        %Q[<li>#{s[:name]} (#{s[:isu_number]})]
      }.join("")
    end

    get '/skater' do
    end

    get '/request' do
      erb :request
    end

    post '/post_request' do
      File.open("request.txt", "a"){|f|
        f.puts params.to_s
      }
      erb "Thank you for your cooperation. Your request has been sent to the administrator who will take over your request and reflect to the system in a while."
    end
  end
end
