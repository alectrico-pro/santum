push:
	ssh-add ~/.ssh/github/cuenta-personal-alectrico-pro/id_ed25519
	git push



assets: 
	docker compose run web rails assets:precompile 

web:
	docker compose run web 

console:
	docker compose run web bundle exec rails c


