# -*- coding: utf-8 -*-
require 'mechanize'
require 'json'
require 'uri'
require 'pry-byebug'
require './competition_watcher'

module CompetitionWatcher
  class Parser
    include CompetitionWatcher::Utils
    def initialize
      @agent = Mechanize.new
      @nbsp = Nokogiri::HTML.parse("&nbsp;").text
    end

    def search_table_by_first_header(page, str)

      tables = page / "table"

      tables.each {|table|
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
      return "" if td.nil?
      return "" if td.search("a").empty?
      return URI.join(site_url, td.search("a").attribute("href")).to_s
    end
    def parse_summary(site_url, offset_timezone="UTC")
          #data = {entry_url: {}, result_url: {}, starting_order_url: {}, judge_score_url: {}, scheduled_date: {}}
      data = {}

      category = ""
      return {} if site_url.nil? || site_url == ""
      page = @agent.get(site_url)

      main_summary_table =  search_main_summary_table(page)
      return {} if main_summary_table.nil?
      main_summary_table.search("tr")[1..-1].each {|tr|
        tds = tr / "td"
        next if tds[0].nil?

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
      #return @categories = data
      return data
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

    def parse_segment_result(result_url)
      data = {}
      page = @agent.get(result_url)
      table = search_table_by_first_header(page, "   Pl.  ")
      return data if table.nil?

      table.search("./tr").each {|tr|
        tds = tr.search("./td")
        next if tds.empty?

        skater_isu_number = 0
        if a = tds[1].search("a")
          bio_url = a.attribute("href").value
          if bio_url.match("http://www.isuresults.com/bios/isufs([0-9]+)\.htm")
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
        #data[ranking] = {ranking: ranking, name: name, nation: nation, points: points, sp: sp, fs: fs}
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
    def parse_category_entries(url)
      data = {}
      page = @agent.get(url)
      if table = search_table_by_first_header(page, "No.")
        table.search("./tr").each {|tr|
          tds = tr.search("./td")
          next if tds.empty?

          number = tds[0].text
          name = tds[1].text
          nation = tds[2].text
          data[number] = {number: number, name: name, nation: nation}
        }
      end
      return data
    end
  end

  ################################################################

  if $0 == __FILE__
    parser = Fisk8::CompetitionParser.new
    p parser.parse_skating_order("http://www.isuresults.com/results/season1516/gpf1516/SEG001.HTM")
    #p parser.parse_segment_result("http://www.isuresults.com/results/season1516/gpjpn2015/SEG001.HTM")
  end
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
