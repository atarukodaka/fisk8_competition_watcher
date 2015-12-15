$LOAD_PATH.push('./lib')

require 'pry-byebug'
require 'competition_watcher'

CompetitionWatcher::Updator.connect_database

comp = Competition.first
category = comp.categories.first
segment = category.segments.first
skater = Skater.first
binding.pry

puts "done"
