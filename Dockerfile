ARG RUBY_VERSION=2.7.5
FROM ruby:$RUBY_VERSION as builder
LABEL MAINTAINER Nervos Network
# RUN sed --in-place --regexp-extended "s/(\/\/)(deb|security).debian.org/\1mirrors.ustc.edu.cn/" /etc/apt/sources.list && \
RUN apt-get update 
# && apt-get upgrade --yes
RUN apt-get install -y  build-essential \
  default-libmysqlclient-dev \
  git \
  nodejs npm \
  libsodium-dev libsecp256k1-dev

RUN npm install -g yarn 
# --registry=https://registry.npm.taobao.org 
# RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ && \
ARG RAILS_ENV=production
ARG BUNDLER_VERSION=2.2.32
ENV RAILS_ENV=$RAILS_ENV
RUN echo ${BUNDLER_VERSION}
RUN gem i -N bundler:${BUNDLER_VERSION}
RUN bundle config --global frozen 1 && \
  bundle config without 'development:test' && \
  bundle config set --local path 'vendor/bundle' && \
  # bundle config mirror.https://rubygems.org https://gems.ruby-china.com && \
  bundle config deployment true


WORKDIR /usr/src/

COPY package.json yarn.lock Rakefile /usr/src/
RUN yarn install
# COPY Gemfile* package.json yarn.lock .yarnrc ./
COPY Gemfile* ./
# ADD vendor/cache vendor/cache
RUN bundle install -j4 --retry 3 && rm -rf vendor/cache
#### ASSETS PRECOMPILATION ####
# COPY app/assets app/assets
# COPY app/javascript app/javascript
# COPY config config
# COPY bin bin
# RUN apk add python2
# RUN RAILS_ENV=${RAILS_ENV} ASSET_HOST=${ASSET_HOST} bundle exec rails assets:precompile 
ADD . /usr/src/
RUN SECRET_KEY_BASE=1 bundle exec rails assets:precompile

FROM ruby:${RUBY_VERSION}-slim
# RUN sed --in-place --regexp-extended "s/(\/\/)(deb|security).debian.org/\1mirrors.ustc.edu.cn/" /etc/apt/sources.list && \
#   apt-get update && apt-get upgrade --yes
RUN apt-get update && apt-get install -y \
  libmariadb3 \
  libcurl4 libjemalloc2 \
  libsodium23 libsecp256k1-0 \
  && rm -rf /var/lib/apt/lists/*
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ARG BUNDLER_VERSION=2.2.32
RUN gem i -N bundler:$BUNDLER_VERSION foreman
EXPOSE 3000
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
WORKDIR /usr/src
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /usr/src /usr/src

