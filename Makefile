SHELL = /bin/sh

install:
	cd root && bundle install

serve:
	cd root && bundle exec jekyll serve --livereload --drafts
