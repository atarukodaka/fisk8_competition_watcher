# -*- coding: utf-8 -*-

require 'mechanize'
require 'json'
require 'uri'
require 'pry-byebug'
#require './competition_watcher'
require 'logger'

module CompetitionWatcher
  class Parser
    include CompetitionWatcher::Utils
    def initialize
      @agent = Mechanize.new
      @nbsp = Nokogiri::HTML.parse("&nbsp;").text
      @log = Logger.new(STDERR)
    end

    def search_table_by_first_header(page, str)
      page.search("table").each {|table|
        elem =  table / "./tr[1]/th[1]"
        return table if elem.text.gsub(@nbsp, " ") == str
        elem =  table / "./tr[1]/td[1]"
        return table if elem.text.gsub(@nbsp, " ") == str
      }
      return nil
    end
    def search_main_summary_table(page)
      search_table_by_first_header(page, "Category") || search_table_by_first_header(page, "カテゴリー")
    end
    def search_time_schedule_table(page)
      search_table_by_first_header(page, "Date")
    end
    def get_href_on_td(site_url, td)
      return "" if td.nil? || td.search("a").empty?
      return URI.join(site_url, td.search("a").attribute("href")).to_s
    end
    def parse_summary(site_url, offset_timezone="UTC")
      data = {}

      category = ""
      return {} if site_url.nil? || site_url == ""
      page = @agent.get(site_url)

      main_summary_table =  search_main_summary_table(page)
      return {} if main_summary_table.nil?

      main_summary_table.search("tr")[1..-1].each {|tr|
        tds = tr / "td"
        next if tds.empty?
        
        if tds[0].text != "" && tds[0].text.ord != 160
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
          data[category][:segment][segment][:order_url] = starting_order_url
          data[category][:segment][segment][:score_url] = judge_score_url
        end
      }

      ## time schedule
      if time_schedule_table = search_time_schedule_table(page)
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

            Time.zone = normalize_timezone(offset_timezone)
            starting_time = Time.zone.parse("#{date} #{time}")
            data[category][:segment][segment][:starting_time] = starting_time
          end
        }
      end
      return data
    end

    ################
    def parse_segment_result(result_url)
      data = {}
      page = @agent.get(result_url)
      table = search_table_by_first_header(page, "   Pl.  ")
      return data if table.nil?

      table.search("./tr").each {|tr|
        tds = tr.search("./td")
        next if tds.empty?

        skater_isu_number = 0
        if !(a = tds[1].search("a")).empty?
          bio_url = a.attribute("href").try(:value)
          if !bio_url.nil? && bio_url.match("http://www.isuresults.com/bios/isufs([0-9]+)\.htm")
            skater_isu_number = $1.to_i
          end
        end
        ranking = tds[0].text
        data[ranking] = {
          ranking: ranking,
          skater_name: tds[1].text,
          skater_nation: tds[2].text,
          skater_isu_number: skater_isu_number,
          tss: tds[3].text,
          tes: tds[4].text,
          pcs: tds[6].text,
          components_ss: tds[7].text,
          components_tr: tds[8].text,
          components_pe: tds[9].text,
          components_ch: tds[10].text,
          components_in: tds[11].text,
          deductions: tds[12].text,
          starting_number: tds[13].text.gsub("#", "").gsub(" ", "")
        }
      }
      return data
    end
    ################
    def parse_skating_order(url)
      data = []
      group_num = 1
      page = @agent.get(url)
      if table = search_table_by_first_header(page, "StN.")
        table.search("./tr").each {|tr|
          tds = tr.search("./td")
          next if tds.empty?

          text0 = tds[0].text.gsub(@nbsp, " ")
          if (text0 =~ /^\s*$/) && (tds[1].text =~ /Warm\-Up Group ([0-9]+)/)
            group_num = $1.to_i
          else
            starting_number = tds[0].text
            name = tds[1].text
            nation = tds[2].text
            data << {starting_number: starting_number, skater_name: name, skater_nation: nation, group: group_num}
          end
        }
        return data
      end
    end
    ################
    def parse_category_entry(url)
      data = []
      page = @agent.get(url)
      if table = search_table_by_first_header(page, "No.")
        table.search("./tr").each {|tr|
          tds = tr.search("./td")
          next if tds.empty?

          number = tds[0].text
          name = tds[1].text
          nation = tds[2].text
          data << {number: number, skater_name: name}
        }
      end
      return data
    end
    def parse_category_result(url)
      data = []
      begin
        page = @agent.get(url)
      rescue Mechanize::ResponseCodeError => e
        case e.response_code
        when "404"
          @log.warn("not found: #{url}")
          return data
        end
      end
      if table = search_table_by_first_header(page, "FPl.")
        table.search("./tr").each {|tr|
          tds = tr.search("./td")
          next if tds.empty?
          
          hash = {
            ranking: tds[0].text.to_i,
            skater_name: tds[1].text,
            skater_nation: tds[2].text,
            points: tds[3].text.to_f
          }
          if tds.size == 6
            hash[:sp_ranking] = tds[4].text.to_i
            hash[:fs_ranking] = tds[5].text.to_i
          elsif tds.size == 5
            hash[:sp_ranking] = tds[4].text.to_i
          end
          data << hash
        }
      end
      return data
    end
      
    def parse_ws
      data = []
      ["Men", "Ladies", "Pairs", "Ice Dance"].each {|category|
        data << parse_ws_category(category)
      }
      return data.flatten
    end
    def parse_ws_category(category)
      url = "http://www.isuresults.com/ws/ws/"
      case category
      when "Men"
        url += "wsmen.htm"
      when "Ladies"
        url += "wsladies.htm"
      when "Pairs"
        url += "wspairs.htm"
      when "Ice Dance"
        url += "wsdance.htm"
      else
        raise "invalid category: '#{category}'"
      end
      data = []
      page = @agent.get(url)
      page.search("table#DataList1.results/tr.content").each {|tr|
        tds = tr.search("./td")
        ws_ranking = tds[0].text.to_i
        ws_points = tds[1].text.to_i
        name = tds[2].search("./a").text
        href = tds[2].search("./a").attribute("href")
        
        if !href.nil?
          href.value =~ /\/bios\/isufs([0-9]+)\.htm/
          isu_number = $1.to_i
        end
        nation = tds[2].search("span").text
        data << {name: name, nation: nation, ws_ranking: ws_ranking, ws_points: ws_points, isu_number: isu_number, category: category}
      }
      return data
    end
    def parse_nationals(url)
      data = []
      page = @agent.get(url)
      page.search("table")[0].search("./tr")[1..-1].each {|tr|
        tds = tr.search("./td")
        date_range = tds[0].text
        city = tds[1].text
        name = tds[3].text.gsub(/[\n\s]*/, "")
        site_url = get_href_on_td(url, tds[3])
        dates = date_range.split("-")
        Time.zone = "Tokyo"
        starting_date = Time.zone.parse(dates[0])
        if dates[1] =~ /([0-9]+)\.([0-9]+)/
          m = $1; d = $2
        else
          m = starting_date.month
          d = dates[1].to_i
        end
        ending_date = Time.zone.parse("%d/%d/%d" % [starting_date.year, m, d])
        data.push({competition_type: "Nationals", hosted_by: "Japan Fed", name: name, city: city, country: "Japan", timezone: "Tokyo", starting_date: starting_date.strftime("%Y/%m/%d"), ending_date: ending_date.strftime("%Y/%m/%d"), site_url: site_url})
      }
      return data
    end
  end
end

  ################################################################

if $0 == __FILE__
  parser = Fisk8::CompetitionParser.new
  parser.parse_nationals("http://www.jsfresults.com/National/2015-2016/fs_j/index.htm")
  p parser.parse_skating_order("http://www.isuresults.com/results/season1516/gpf1516/SEG001.HTM")
  #p parser.parse_segment_result("http://www.isuresults.com/results/season1516/gpjpn2015/SEG001.HTM")
end

if false
  site_url = "http://www.isuresults.com/results/season1516/gpjpn2015/"
  #site_url = "http://www.isuresults.com/results/season1516/gpusa2015/"
  #site_url = "http://www.lev-nrw.org/docs/event/1469/index.htm"
  #site_url = "http://www.tvoj-toner.com/goldenspin/index.htm"
  #site_url = "http://www.figureskatingresults.fi/results/1516/CSFIN2015/"
  #site_url = "http://www.isuresults.com/results/season1516/jgpcro2015/"
  #site_url = "file://file:///home/vagrant/src/fisk8/competition_summary/gpjpn15.html"
  

  #puts result.to_json
  #data = parser.parse_results(data)
  #puts data.to_json
  #puts parser.categories.to_json

end
