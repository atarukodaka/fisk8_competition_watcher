BE = bundle exec



update:
	$(BE) ruby competition_watcher.rb

app:
	$(BE) rackup -o 192.168.33.10 -p 9292

clean:
	rm -rf *~

reset_db:
	$(BE) rake db:migrate VERSION=000
	$(BE) rake db:migrate VERSION=001


db_env:
	export HEROKU_POSTGRESQL_TEAL_URL="postgres://gyvvjhypopgqml:0X8zZxtCu-lqynSY8s6AOuGeG9@ec2-54-204-41-175.compute-1.amazonaws.com:5432/d9okbg9ud42sd"
