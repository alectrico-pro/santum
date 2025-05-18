assets: 
	docker compose run web rails assets:precompile 

web:
	docker compose run web 

console:
	docker compose run web bundle exec rails c


