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
  module Utils
    def self.abbr(str)
      case str
      when "Short Program"; "SP"
      when "Free Skating"; "FS"
      when "Short Dance"; "SD"
      when "Free Dance"; "FD"
      else str
      end
    end

    def self.link_to(url, text)
      if url.to_s != ""
        text
      else
        %Q[<a href="#{url}">text</a>]
      end
    end
    def self.normalize_timezone(tz)
      if tz =~ /^UTC(.*)$/
        tz = $1.to_i
      end
      return tz || "UTC"
    end
  end
  ################################################################
  class Database
    def self.connect_database
      local_db_address = "postgresql://postgres@192.168.33.10/competition_db"
      db_address = ENV['HEROKU_POSTGRESQL_TEAL_URL'] || local_db_address
      ActiveRecord::Base.establish_connection(db_address)
    end

    def initialize
      @log = Logger.new(STDERR)
      self.class.connect_database
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

        #if (c[:timezone] =~ /^UTC([\+\-].*)/)
        #  c[:timezone] = $1.to_i
        #end

        headers.each {|h| competition[h] = c[h] }
        competition.save

        @log.info("#{c[:name]},  #{c[:site_url]}")
        
        site_url = c[:site_url]
        parser = Fisk8::CompetitionParser.new
        summary = parser.parse_summary(site_url, c[:timezone])
        
        ## 
        summary.each {|cat, value|
          @log.info(" category of #{cat} on #{c[:name]}")
          category = competition.categories.find_or_create_by(name: cat)
          category.entry_url = value[:entry_url]
          category.result_url = value[:result_url]
          category.save
          value[:segment].each {|seg, v|
            if segment = category.segments.find_by_name(seg)
            else
              segment = category.segments.create(name: seg)
            end
            @log.info("  segment of #{seg}")
            segment.starting_time = v[:starting_time]
            segment.order_url = v[:order_url]
            segment.score_url = v[:score_url]

            @log.info("    parging segment result (#{segment.order_url})")
            seg_data = parser.parse_segment_result(segment.order_url)
            seg_data.each {|k, vv|
              seg_res = segment.segment_results.find_or_create_by(ranking: k)
              seg_res.update(vv)
              skater = Skater.find_or_create_by(name: vv[:skater_name])
              skater.nation = vv[:skater_nation]
              skater.isu_number = vv[:skater_isu_number]
              skater.category = category.name
              skater.save
              seg_res.skater_id = skater.id
              seg_res.save
            }
            ## result
            segment.save
          }
        }
      }
    end

    def update_starting_time
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
  watcher.update_starting_time
  watcher.update_skaters
end
