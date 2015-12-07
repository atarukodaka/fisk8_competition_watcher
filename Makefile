



clean:
	rm -rf *~

reset_db:
	bundle exec rake db:migrate VERSION=000
	bundle exec rake db:migrate VERSION=001
