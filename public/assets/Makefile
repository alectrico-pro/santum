RUBY = ruby
ERB = erb
KINDLEGEN = bin/kindlegen

#agregar copyright
%.jpg.tmp: %.jpg
	convert -background '#0008' -fill white -gravity  center -size 310x100 \
        caption:"© alectrico ® 2022 " \
        $^.jpg +swap -gravity south -composite $^.jpg.tmp           

#pone título TITULO a la imagen en ARCHIVO
tit:  
	convert -background '#0008' -fill white -gravity  center -size 2510x510 \
        caption:"A" \
        $^.jpg +swap -gravity south -composite $^.jpg ; \


pyt:
	docker build bot -t pyt -f python.Dockerfile
	docker run -it --rm -e PUID=1000 -e PGUID=1000 -v $(PWD)/bot/:/app pyt bash
.PHONY: bot
bot:
	docker compose build bot
	docker compose up bot

pbot:
	docker compose build babot
	docker compose up babot 
	docker compose exec babot bash


calibre:
	docker compose run calibre-web

mobi:
	docker run --name documentacion --rm -e PUID=1000 -e PGID=1000 -p 4001:4000 -v $(shell pwd)/documentacion:/srv/jekyll jekyll/jekyll bash -c 'jekyll build . ' 
	-$(KINDLEGEN) documentacion/mobi.opf 
	docker run --name epub --rm -it -e PUID=1000 -e PGID=1000 -e PASSWORD= `optional` -e CLI_ARGS= `optional` -p 8080:8080 -p 8081:8081 -v $(shell pwd)/documentacion/:/doc lscr.io/linuxserver/calibre bash -c 'cd doc  && ls &&  ebook-convert mobi.mobi book.epub' 
	docker run --name epub --rm -it -e PUID=1000 -e PGID=1000 -e PASSWORD= `optional` -e CLI_ARGS= `optional` -p 8080:8080 -p 8081:8081 -v $(shell pwd)/documentacion/:/doc lscr.io/linuxserver/calibre bash -c ' ebook-convert book.epub && ebook-viewer book.epub'
RUBY_VERSION = 2.6.5
#RUBY_VERSION = 3.1.0
#RUBY_VERSION='3.1.0'
PG_MAJOR='14'
NODE_MAJOR='16'
YARN_VERSION='1.22.17'
DISTRO_NAME='bullseye'



#revisar este link
#https://semaphoreci.com/community/tutorials/dockerizing-a-ruby-on-rails-application



rustc:
	docker compose up rustc

#titula todas las cubiertas que estén en volumenes.txt
alectricon:
	docker build . -t alectricon
	docker run -e PUID=1000 -e PGID=1000 -v $(shell pwd)/:/myapp alectricon

pendientes:
	docker compose up pendientes

alectricon:
	docker run -it -e PUID=1000 -e PGID=1000 -v $(shell pwd)/:/myapp alectricon /bin/sh

tone:
	docker compose up tone

volumen:
	docker volume create --name bundle

debug:
	docker compose run debug bash -c "bundle exec rspec spec/requests/api/v1/comercio/servicios_spec.rb:259"

oro:
	git push oromolido


alectrica-s:
	git push alectrica-s

up:
	docker compose up

console: 
	docker  compose up console

usuario:
	docker compose up usuario


cucumber:
	docker compose up cucumber

migrate:
	docker compose up db-migrate

web:
	docker compose up web

bash:
	docker compose run bash

vim:
	docker compose exec -it web vim

tbk:
	docker compose up tbk

test:
	docker compose up test

build:
	docker compose build \
                --build-arg DISTRO_NAME=${DISTRO_NAME} \
                --build-arg RUBY_VERSION=${RUBY_VERSION} \
                --build-arg PG_MAYOR=${PG_MAJOR} \
                --build-arg NODE_MAJOR=${NODE_MAJOR} \
                --build-arg YARN_VERSION=${YARN_VERSION}; \ 
	make vars


vars:
	if rm .env; then echo 'borrado .env'; else echo "";  fi
	echo   " DISTRO_NAME=${DISTRO_NAME} \n RUBY_VERSION=${RUBY_VERSION} \n PG_MAYOR=${PG_MAJOR} \n NODE_MAJOR=${NODE_MAJOR} \n YARN_VERSION=${YARN_VERSION} " >> .env

down:
	docker compose stop
	docker compose down

clean:    
	docker system prune --force
	docker volume prune --force
	docker network prune --force




rustcurl:
	docker compose up rustcurl

rust:  
	docker compose run rust


www:
	docker compose run www



.PHONY: repair
repair:
	docker run --name repair-c -it --rm -e PUID=1000 -e PGID=1000 -v $(shell pwd)/repair:/root/ repair wrangler preview



repconfig:
	docker run --name repair-c -it --rm -e PUID=1000 -e PGID=1000 -v $(shell pwd)/repair:/root/ repair wrangler config



repgen:
	docker run --name repgen-c -it --rm -e USER=tio -e PUID=1000 -e PGID=1000 -v $(shell pwd)/gen:/root repair bash -c "pwd && ls && wrangler generate projectname https://github.com/cloudflare/worker-template "




repview:
	docker run --name repgen-c -it --rm -e USER=tio -e PUID=1000 -e PGID=1000 -v $(shell pwd)/gen/projectname:/root repair bash -c "pwd && ls && wrangler dev"




repinit:
	docker run --name repair-c -it --rm -e PUID=1000 -e PGID=1000 -v $(shell pwd)/repair:/root repair bash -c "pwd && ls && wrangler dev"


repotro:
	docker run --name otro-repair-c -it --rm -e PUID=1000 -e PGID=1000 -v $(shell pwd)/otro-repair:/root repair bash -c "pwd && ls && wrangler preview "


repcfg:
	docker run --name repair-c -it --rm -e PUID=1000 -e PGID=1000 -v $(shell pwd)/repair:/root repair bash -c " wrangler config "



#rep:
#	docker run --name repair-c -it --rm -e USER=tio -e PUID=1000 -e PGID=1000 -v $(shell pwd)/rep/.wranger/config/:/root/.wrangler/config repair wrangler dev




ping:
	docker compose run ping


mach: 
	docker compose run mach

heroku:
	rcm7/heroku-cli 



