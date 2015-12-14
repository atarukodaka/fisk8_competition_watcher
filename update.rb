$LOAD_PATH.push('./lib')

require 'competition_watcher'

CompetitionWatcher::Updator.connect_database

def run
  updator = CompetitionWatcher::Updator.new

  binding.pry

  case ARGV[0]
    when "nationals"
      updator.update_nationals
    when "skaters"
      updator.update_skaters
    else
    updator.update
    updator.update_starting_time
  end
end

run
