require './app'

use ActiveRecord::ConnectionAdapters::ConnectionManagement  ## see http://qiita.com/myokkie/items/6f65db5d53f19d34a27c#2-2

run CompetitionWatcher::Application
