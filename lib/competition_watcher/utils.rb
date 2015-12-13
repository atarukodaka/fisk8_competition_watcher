module CompetitionWatcher
  module Utils
    def abbr(str)
      case str
      when "Short Program"; "SP"
      when "Free Skating"; "FS"
      when "Short Dance"; "SD"
      when "Free Dance"; "FD"
      else str
      end
    end

    def normalize_timezone(tz)
      if tz =~ /^UTC(.*)$/
        tz = $1.to_i
      end
      return tz || "UTC"
    end
  end
end
