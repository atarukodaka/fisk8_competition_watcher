$LOAD_PATH.push('./lib')

require 'competition_watcher'

CompetitionWatcher::Updator.connect_database


def run
  updator = CompetitionWatcher::Updator.new
  updator.update
  updator.update_starting_time
  updator.update_skaters
end

run
