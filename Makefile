BE = bundle exec



update:
	$(BE) ruby update.rb

update_nationals:
	$(BE) ruby update.rb nationals

app:
	$(BE) rackup -o 192.168.33.10 -p 9294

clean:
	rm -rf *~

reset_db:
	$(BE) rake db:migrate VERSION=000
	$(BE) rake db:migrate VERSION=001

push_heroku:
	git push heroku master

push_git:
	git push origin master

push: push_heroku push_git	
