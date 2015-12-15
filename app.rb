$LOAD_PATH.push('./lib')

require 'sinatra/base'
require 'sinatra/reloader'

require 'action_view'
require 'action_view/helpers'
require 'action_view/helpers/date_helper'
require 'action_view/helpers/tag_helper'

require 'competition_watcher'

CompetitionWatcher::Updator.connect_database

module CompetitionWatcher
  class Application < Sinatra::Base
    register Sinatra::Reloader

    set :port, 1234
    set :bind, '0.0.0.0'

    enable :inline_templates
    include ERB::Util
    include CompetitionWatcher::Utils
    include ActionView::Helpers::DateHelper  # for time_ago_in_words
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper

    helpers do
      include CompetitionWatcher::Utils
    end

    ################
    get '/' do
      erb :home
    end

    get '/competitions' do
      page = (params[:p] || params[:page] || 1).to_i
      per_page = 5
      max_page = ((Competition.count-1)/3).to_i + 1
      
      starting = [(page-1)*per_page, Competition.count].min
      ending = starting+per_page-1
      competitions = Competition.order("starting_date desc")[starting..ending]

      erb :competitions, locals: {competitions: competitions, page: page, max_page: max_page}
    end

    get '/competition/:comp_key' do
      key = params[:comp_key]
      if competition = Competition.find_by_key(key)
        erb :competition, locals: {competition: competition}
      else
        erb "#{h key} not found"
      end
    end

    get '/skating_order/:comp_key/:category/:segment' do
      erb :skating_order
    end
    get '/result/:comp_key/:category' do
      erb :category_result
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

    get '/skaters/:category' do
      erb :skaters
    end
    get '/skater/:isu_number' do
      erb :skater
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
