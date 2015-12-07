require 'active_record'
require 'yaml'
require 'pg'
require 'pry-byebug'
require 'csv'
require 'logger'

require './model.rb'
require './competition_parser.rb'

module CompetitionWatcher
  class Database
    def initialize
      @log = Logger.new(STDERR)
      connect_database
    end
    def connect_database
      @log.info("connection to database...")
      connection = PG::connect(host: "192.168.33.10", user: "postgres", password: "postgres", port: "5432", dbname: "competition_db")
      
      ActiveRecord::Base.configurations = YAML.load_file('database.yml')
      ActiveRecord::Base.establish_connection(:development)
    end

    def update
      # read input table
      competition_csv_filename = "competitions.csv"
      @log.info(" read #{competition_csv_filename}...")
      tbl = CSV::table(competition_csv_filename)
      headers = tbl.headers

      tbl.each {|c|   ## for each competitions
        ## database
        competition = Competition.find_by_key(c[:key])
        competition = Competition.create if competition.nil?
        headers.each {|h| competition[h] = c[h] }
        competition.save

        @log.info("#{c[:name]},  #{c[:site_url]}")
        
        site_url = c[:site_url]
        parser = Fisk8::CompetitionParser.new(site_url)
        parser.offset_timezone = c[:timezone]
        summary = parser.parse_summary
        
        ## entry
        summary.each {|category, value|
          @log.info(" entry for #{category} on #{value[:entry_url]}")

          ## clear entries if exists to avoid duplication
          competition.entries.where(category: category).each {|e|
            e.destroy
          }
          
          hash = parser.parse_category_entries(value[:entry_url])
          hash.each {|k, v|
            entry = competition.entries.create(category: category, number: v[:number])
            skater_name = v[:name]
            skater_nation = v[:nation]
            
            if skater = Skater.find_by_name(skater_name)
              entry.skater_id = skater.id
            else
              skater = Skater.create(name: skater_name, nation: skater_nation)
              skater.save
              entry.skater_id = skater.id
            end
            entry.save
          }
        }
      }
      
    end
  end
end

if $0 == __FILE__
  updator = CompetitionWatcher::Database.new
  updator.update
end
