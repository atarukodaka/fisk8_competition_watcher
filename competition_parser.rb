require 'mechanize'
require 'json'
require 'uri'

module Fisk8
  class CompetitionParser
    def initialize
      @agent = Mechanize.new
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
    def get_href_on_td(site_url, td)
      return "" if td.search("a").empty?
      return URI.join(site_url, td.search("a").attribute("href")).to_s
    end
    def parse_summary(site_url, offset_timezone="")
      #data = {entry_url: {}, result_url: {}, starting_order_url: {}, judge_score_url: {}, scheduled_date: {}}
      data = {}

      category = ""

      page = @agent.get(site_url)
      main_summary_table =  search_main_summary_table(page)
      return {} if main_summary_table.nil?
      main_summary_table.search("tr").each {|tr|
        tds = tr / "td"
        next if tds[0].nil?

        if tds[0].text != ""
          category = tds[0].text
          entry_url = get_href_on_td(site_url, tds[2])
          result_url = get_href_on_td(site_url, tds[3])
          data[category] = {entry_url: entry_url, result_url: result_url, segment: {}}
        elsif tds[1].text != ""
          segment = tds[1].text
          starting_order_url = get_href_on_td(site_url, tds[3])
          judge_score_url = get_href_on_td(site_url, tds[4])

          if data[category][:segment][segment].nil?
            data[category][:segment][segment] = {}
          end
          data[category][:segment][segment]["starting_order_url"] = starting_order_url
          data[category][:segment][segment]["judge_score_url"] = judge_score_url
        end
      }

      ## time schedule
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

          data[category][:segment][segment]["starting_time"] = DateTime.parse("#{date} #{time}").new_offset(offset_timezone || 0)
        end
      }
      #return @categories = data
      return data
    end
    def adjust_time_zone(data, tz)
      ## yet : new_offset
    end

    ################
    def search_result_table(page)
      return search_table_by_first_header(page, "FPl.")
    end
    def parse_category_result(category, result_url)
      data = {}
      page = @agent.get(result_url)
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
        data[num] = {num: num, name: name, nation: nation, points: points, sp: sp, fs: fs}
      }
      return data
    end
    def parse_results(data)
      data.each {|category, value|
        data[category]["result"] = parse_category_result(category, value[:result_url])
      }
      return data
    end

    def parse_category_entries(url)
      data = {}
      page = @agent.get(url)
      table = search_table_by_first_header(page, "No.")
      table.search("./tr").each {|tr|
        tds = tr.search("./td")
        next if tds.empty?
        
        number = tds[0].text
        name = tds[1].text
        nation = tds[2].text
        data[number] = {number: number, name: name, nation: nation}
      }
      return data
    end
  end
end

################################################################

if $0 == __FILE__
  parser = Fisk8::CompetitionParser.new(nil)
  entry_url = "http://www.isuresults.com/results/season1516/gpjpn2015/CAT001EN.HTM"
  
  puts parser.parse_category_entries(entry_url)

end

if false
  site_url = "http://www.isuresults.com/results/season1516/gpjpn2015/"
  #site_url = "http://www.isuresults.com/results/season1516/gpusa2015/"
  #site_url = "http://www.lev-nrw.org/docs/event/1469/index.htm"
  #site_url = "http://www.tvoj-toner.com/goldenspin/index.htm"
  #site_url = "http://www.figureskatingresults.fi/results/1516/CSFIN2015/"
  #site_url = "http://www.isuresults.com/results/season1516/jgpcro2015/"
  #site_url = "file://file:///home/vagrant/src/fisk8/competition_summary/gpjpn15.html"
  
  parser = Fisk8::CompetitionParser.new(site_url)
  parser.offset_timezone = "UTC+9"
  summary = parser.parse_summary
  puts summary.to_json
  result = {}
  summary.each {|category, value|
    result[category] = parser.parse_category_result(category, value[:result_url])
  }
  #puts result.to_json
  #data = parser.parse_results(data)
  #puts data.to_json
  #puts parser.categories.to_json

end






