FROM ruby:3.3.6-slim
#FROM ruby:3.2.1-slim
#ROM ruby:3.0.5-slim

#Curl es usado por typhoeus

#de rails seven
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    libcurl4-openssl-dev \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
    libvips \
    libpq-dev \
    libyaml-dev \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3
  
RUN gem update --system && gem install bundler

WORKDIR /usr/src/app

#OPY ./Gemfile /usr/src/app/Gemfile

COPY Gemfile* ./
#RUN bundle config unset frozen \
# && bundle config unset deployment \
# && bundle config frozen true \
# && bundle config jobs 4 \
# && bundle config deployment true \
# && bundle config without 'development test' \
# && bundle install
COPY . .
#ENTRYPOINT ["./entrypoint.sh"]
#RUN bundle install --gemfile /usr/src/app/Gemfile
#COPY Gemfile.lock /usr/src/app/Gemfile

RUN bundle install
EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
