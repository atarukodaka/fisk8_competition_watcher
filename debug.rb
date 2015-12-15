$LOAD_PATH.push('./lib')

require 'pry-byebug'
require 'competition_watcher'
require 'competition_watcher/database'

binding.pry

comp = Competition.first
category = comp.categories.first
segment = category.segments.first
skater = Skater.first


puts "done"


