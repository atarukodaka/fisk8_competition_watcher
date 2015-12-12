require 'sinatra/base'
require 'sinatra/reloader'

require './competition_watcher'

CompetitionWatcher::Database.connect_database

module CompetitionWatcher
  class Application < Sinatra::Base
    register Sinatra::Reloader

    set :port, 1234
    set :bind, '0.0.0.0'

    enable :inline_templates
    include ERB::Util
    include CompetitionWatcher::Utils

    helpers do
      include CompetitionWatcher::Utils
    end

    ################
    get '/' do
      erb :home
    end

    get '/competitions' do
      competitions = Competition.all.order("starting_date desc")

      erb competitions.map {|c|
        %Q[<li>#{c[:key]} / <a href="/competition?key=#{c[:key]}">#{c[:name]}</a>]
      }.join("")
      
      erb :competitions, locals: {competitions: competitions}
    end

    get '/competitions/json' do
      Competition.all.to_json
    end

    get '/competition/:comp_key' do
      key = params[:comp_key]
      if competition = Competition.find_by_key(key)
        erb :competition, locals: {competition: competition}
      else
        erb "#{CGI.escapeHTML(key)} not found"
      end
    end

    get '/skating_order/:comp_key/:category/:segment' do
      erb :skating_order
    end
    get '/result/:comp_key/:category/:segment' do
      erb :segment_result
    end

    get '/calendar' do
      erb :calendar
    end
    ################################################################
    get '/skaters' do
      erb :skaters
    end

    get '/skaters/men' do
      erb "hoge"
    end
    get '/skater' do
    end
    ################################################################
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
