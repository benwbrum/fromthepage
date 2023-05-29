# Based off of Ryan Baumann's Docker image, https://github.com/ryanfb/docker_fromthepage
# and the base Ruby on Rails configuration, https://github.com/microsoft/vscode-dev-containers/tree/main/containers/ruby-rails

# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.1, 3.0, 2, 2.7, 2.6, 3-bullseye, 3.1-bullseye, 3.0-bullseye, 2-bullseye, 2.7-bullseye, 2.6-bullseye, 3-buster, 3.1-buster, 3.0-buster, 2-buster, 2.7-buster, 2.6-buster
ARG VARIANT=2.7
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}
ARG MYSQL_USERNAME
ARG MYSQL_PASSWORD

# Install Ruby, RubyGems, Bundler, ImageMagick, MySQL and Git
# Install qt4/qtwebkit libraries for capybara
# Install build deps for gems installed by bundler
RUN apt-get update && apt-get install -y imagemagick libmagickwand-dev \
    git graphviz tzdata \
    build-essential && \
    apt-get install -y \
      $(apt-get -s build-dep ruby-rmagick | grep '^(Inst|Conf) ' | cut -d' ' -f2 | fgrep -v 'ruby') && \
    apt-get install -y \
      $(apt-get -s build-dep ruby-mysql2 | grep '^(Inst|Conf) ' | cut -d' ' -f2 | fgrep -v -e 'mysql-' -e 'ruby')

# Set the locale.
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install bundler
RUN gem install bundler

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains 
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.app.github.dev"

# Install Nodejs and MariaDB
RUN sudo apt-get update
RUN sudo apt-get install -y nodejs
RUN sudo apt-get install -y default-mysql-server default-mysql-client default-libmysqlclient-dev

# Create MySQL user for rails to use, uses variables passed from devcontainer.json
RUN sudo service mariadb start && \
    sudo mysql -e "CREATE USER $MYSQL_USERNAME@localhost IDENTIFIED BY '$MYSQL_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USERNAME'@localhost IDENTIFIED BY '$MYSQL_PASSWORD';"
