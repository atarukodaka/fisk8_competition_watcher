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
