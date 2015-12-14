require 'logger'
require 'active_record'

module CompetitionWatcher
  class Updator
    def self.connect_database
      local_db_address = "postgresql://postgres@192.168.33.10/competition_db"
      db_address = ENV['HEROKU_POSTGRESQL_TEAL_URL'] || local_db_address
      ActiveRecord::Base.establish_connection(db_address)
    end

    def initialize
      @log = Logger.new(STDERR)
      @competition_csv_filename = "competitions.csv"
      self.class.connect_database
    end
    def update
      # read input table
      @log.info(" read #{@competition_csv_filename}...")
      tbl = CSV::table(@competition_csv_filename, encoding: "Shift_JIS:UTF-8")
      headers = tbl.headers

      tbl.each {|c|   ## for each competitions
        next if c[:key].nil? || c[:updating] == "skip"
        @log.info("#{:key}: #{c[:name]} on  #{c[:site_url]}")
        created = false
        competition = Competition.find_or_create_by(key: c[:key]){
          created = true
        }
        headers.each {|h| competition[h] = c[h] }
        competition.save
        if (!created) && (c[:updating] != "force") && (c[:site_url].to_s != "")
          agent = Mechanize.new
          last_modified = agent.head(c[:site_url])["last-modified"]
          if last_modified < competition.updated_at
            @log.info(" --- skip as not modified")
            next
          end
        end

        site_url = c[:site_url]
        parser = CompetitionWatcher::Parser.new
        summary = parser.parse_summary(site_url, c[:timezone])
        
        ## 
        summary.each {|cat, value|
          @log.info(" category of #{cat} on #{c[:name]}")
          category = competition.categories.find_or_create_by(name: cat)
          category.entry_url = value[:entry_url]
          category.result_url = value[:result_url]
          category.save

          ## category entry
          data = parser.parse_category_entry(category.entry_url)
          data.each {|item|
            entry = category.entries.find_or_create_by(number: item[:number])
            entry.number = item[:number]
            entry.category = category
            entry.skater = Skater.find_or_create_by(name: item[:skater_name])
            entry.save
          }
          ## category result
          data = parser.parse_category_result(category.result_url)
          data.each {|item|
            res = category.category_results.find_or_create_by(ranking: item[:ranking])
            res.update(item)
            res.skater = Skater.find_or_create_by(name: item[:skater_name])
            res.save
          }
          ## segment
          value[:segment].each {|seg, v|
            @log.info("  segment of #{seg}")
            segment = category.segments.find_or_create_by(name: seg)
            segment.starting_time = v[:starting_time]
            segment.order_url = v[:order_url]
            segment.score_url = v[:score_url]

            @log.info("    parsing segment result (#{segment.order_url})")
            # try order first
            orders = parser.parse_skating_order(segment.order_url)
            if (! orders.nil?) && (! orders.empty?)
              orders.each {|data|
                order = segment.skating_orders.find_or_create_by(starting_number: data[:starting_number])
                ## yet: update skater info
                order.update(data)
                order.save
              }
            else
              # try result then
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
            end
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
        @log.info("set starting time for #{comp_key}/#{cat}/#{seg} at #{time_str} (#{competition.timezone})")
        Time.zone = competition.timezone

        category = competition.categories.find_by_name(cat)
        segment = category.segments.find_by_name(seg)
        segment.starting_time = Time.zone.parse(time_str)
        segment.save
      end
    end
    ################
    def update_nationals
      parser = CompetitionWatcher::Parser.new      
      season = "2015-16"   # yet
      data = parser.parse_nationals("http://www.jsfresults.com/National/2015-2016/fs_j/index.htm")  # yet
      tbl_competitions = CSV::table(@competition_csv_filename, encoding: "Shift_JIS:UTF-8")
      headers = tbl_competitions.headers

      rows = []
      data.each {|hash|
        vs = headers.map {|header| v = hash[header.to_sym]; (v)? v.encode("Shift_JIS") : nil}
        rows << CSV::Row.new(headers, vs)
      }
      tbl = CSV::Table.new(rows)
      puts tbl.to_csv
    end
    ################
    def update_skaters
      parser = CompetitionWatcher::Parser.new
      @log.info("parsing world standings")
      data = parser.parse_ws
      @log.info("parse done")
      data.each {|item|
        skater = Skater.find_or_create_by(name: item[:name])
        skater.update(item)
        skater.personal_best = PersonalBest.create if skater.personal_best.nil?
        skater.sp_personal_best = SpPersonalBest.create if skater.sp_personal_best.nil?
        skater.fs_personal_best = FsPersonalBest.create if skater.fs_personal_best.nil?
        skater.save
      }
    end
  end  ## class
end

if $0 == __FILE__
  watcher = CompetitionWatcher::Database.new

  wathcer.update_nationals
  watcher.update
  watcher.update_starting_time
  watcher.update_skaters
end
