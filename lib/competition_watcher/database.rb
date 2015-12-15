require 'active_record'
require 'competition_watcher/model'

module CompetitionWatcher
  class Database
    def self.connect_database
      local_db_address = "postgresql://postgres@192.168.33.10/competition_db"
      db_address = ENV['DATABASE_URL'] || local_db_address
      Logger.new(STDERR).info("connecting database: #{db_address}")
      ActiveRecord::Base.establish_connection(db_address)
    end
  end
end

CompetitionWatcher::Database.connect_database
