$LOAD_PATH.push('./lib')

require 'pry-byebug'
require 'competition_watcher'

CompetitionWatcher::Updator.connect_database

table = "segment_results";
ActiveRecord::Base.connection.execute("DROP TABLE #{table}")


comp = Competition.first
category = comp.categories.first
segment = category.segments.first
skater = Skater.first
binding.pry

puts "done"


