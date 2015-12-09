# -*- coding: utf-8 -*-
require 'active_support/core_ext/time/zones'
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
      local_db_address = "postgresql://postgres@192.168.33.10/competition_db"
      db_address = ENV['HEROKU_POSTGRESQL_TEAL_URL'] || local_db_address
      @log.info("connection to database...#{db_address}")
      ActiveRecord::Base.establish_connection(db_address)
    end

    def update
      # read input table
      competition_csv_filename = "competitions.csv"
      @log.info(" read #{competition_csv_filename}...")
      tbl = CSV::table(competition_csv_filename, encoding: "Shift_JIS:UTF-8")
      headers = tbl.headers

      tbl.each {|c|   ## for each competitions
        next if c[:name].nil? || c[:updating] == "skip"
       ## database
        competition = Competition.find_by_key(c[:key])
        competition = Competition.create if competition.nil?

        if (c[:timezone] =~ /^UTC([\+\-].*)/)
          c[:timezone] = $1.to_i
        end

        headers.each {|h| competition[h] = c[h] }
        competition.save

        @log.info("#{c[:name]},  #{c[:site_url]}")
        
        site_url = c[:site_url]
        parser = Fisk8::CompetitionParser.new
        summary = parser.parse_summary(site_url, c[:timezone])
        
        ## 
        summary.each {|cat, value|
          @log.info(" entry for #{cat} on #{value[:entry_url]}")
          if category = competition.categories.find_by_name(cat)
          else
            category = competition.categories.create(name: cat)
          end
          category.entry_url = value[:entry_url]
          category.result_url = value[:result_url]
          value[:segment].each {|seg, v|
            if segment = category.segments.find_by_name(seg)
            else
              segment = category.segments.create(name: seg)
            end
            segment.starting_time = v["starting_time"]
            segment.order_url = v[:order_url]
            segment.score_url = v[:score_url]
            segment.save
            
          }
          category.save
          ## entry
          if false
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
              else
                skater = Skater.create(name: skater_name, nation: skater_nation, category: category)
                skater.save
              end
              entry.skater_id = skater.id
              entry.save
            }
          end
        }
        
      }
    end

    def addhoc_starting_time
      starting_time_csv_filename = "starting_time.csv"
      tbl = CSV::table(starting_time_csv_filename, encoding: "Shift_JIS:UTF-8")
      tbl.each {|data|
        set_starting_time(data[:competition_key], data[:category], data[:segment], data[:starting_time])
      }
    end
    def set_starting_time(comp_key, cat, seg, time_str)
      if competition = Competition.find_by_key(comp_key)
        @log.info("set starting time for #{comp_key}/#{cat}/#{seg} at #{time_str}")
        Time.zone = competition.timezone

        category = competition.categories.find_by_name(cat)
        segment = category.segments.find_by_name(seg)
        segment.starting_time = Time.zone.parse(time_str)
        segment.save
      end
    end
    def update_skaters
    end
  end  ## class
end

if $0 == __FILE__
  watcher = CompetitionWatcher::Database.new
  watcher.update
  watcher.addhoc_starting_time

  watcher.update_skaters
end
