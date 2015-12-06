require 'mechanize'
require 'json'
require 'uri'

module Fisk8
  class CompetitionParser
    attr_accessor :site_url, :offset_timezone, :categories

    def initialize(site_url)
      @site_url = site_url
      @agent = Mechanize.new

      @offset_timezone = nil
      @categories = {}
    end

    def search_table_by_first_header(page, str)
      tables = page / "table"

      tables.each {|table|
        elem =  table / "./tr[1]/th[1]"
        # puts "* '#{elem.text}' vs '#{str}': #{elem.text == str}"
        return table if elem.text == str
      }
      return nil
    end
    def search_main_summary_table(page)
      search_table_by_first_header(page, "Category")
    end
    def search_time_schedule_table(page)
      search_table_by_first_header(page, "Date")
    end
    def get_href_on_td(td)
      return URI.join(site_url, td.search("a").attribute("href")).to_s
    end
    def parse_summary
      data = {}
      category = ""

      page = @agent.get(site_url)
      main_summary_table =  search_main_summary_table(page)

      main_summary_table.search("tr").each {|tr|
        tds = tr / "td"
        next if tds[0].nil?

        if tds[0].text != ""
          category = tds[0].text
          entries_url = get_href_on_td(tds[2])
          result_url = get_href_on_td(tds[3])
          data[category] = {entries: entries_url, result_url: result_url}
        elsif tds[1].text != ""
          segment = tds[1].text
          starting_order_url = get_href_on_td(tds[3])
          judge_score_url = get_href_on_td(tds[4])
          data[category][segment] = {}
          data[category][segment]["starting_order"] = starting_order_url
          data[category][segment]["judge_score_url"] = judge_score_url
        end
      }

      time_schedule_table = search_time_schedule_table(page)
      date = time = ""
      time_schedule_table.search("tr").each {|tr|
        tds = tr / "td"
        next if tds[0].nil?
        if tds[0].text != ""
          date = tds[0].text
        else
          time = tds[1].text
          category = tds[2].text
          segment = tds[3].text
          data[category][segment]["datetime"] = DateTime.parse("#{date} #{time}").new_offset(@offset_timezone)
        end
      }
      return @categories = data
      #return data
    end
    def adjust_time_zone(data, tz)
      ## yet : new_offset
    end

    ################
    def search_result_table(page)
      return search_table_by_first_header(page, "FPl.")
    end

    def parse_results

      @categories.each {|category, value|
        @categories[category]["result"] = {}
        page = @agent.get(value[:result_url])
        table = search_result_table(page)
        table.search("./tr").each {|tr|
          tds = tr.search("./td")
          next if tds.empty?

          num = tds[0].text
          name = tds[1].text
          nation = tds[2].text
          points = tds[3].text
          sp = tds[4].text
          fs = tds[5].text
          @categories[category]["result"][num] = {num: num, name: name, nation: nation, points: points, sp: sp, fs: fs}
        }
      }
    end
  end
end

################################################################

if $0 == __FILE__
  site_url = "http://www.isuresults.com/results/season1516/gpjpn2015/"
  #site_url = "http://www.isuresults.com/results/season1516/gpusa2015/"
  #site_url = "http://www.lev-nrw.org/docs/event/1469/index.htm"
  #site_url = "http://www.tvoj-toner.com/goldenspin/index.htm"
  #site_url = "http://www.figureskatingresults.fi/results/1516/CSFIN2015/"
  #site_url = "http://www.isuresults.com/results/season1516/jgpcro2015/"
  #site_url = "file://file:///home/vagrant/src/fisk8/competition_summary/gpjpn15.html"
  
  parser = Fisk8::CompetitionParser.new(site_url)
  parser.offset_timezone = "UTC+9"
  parser.parse_summary
  parser.parse_results
  puts parser.categories.to_json
end






