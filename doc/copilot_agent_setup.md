# GitHub Copilot Agent Setup

This guide explains how to configure a shell environment so that GitHub Copilot Agent (or any
other automated assistant) can lint and test FromThePage in the same way that CI does.

## 1. Start required services

Launch MySQL 5.7 and Elasticsearch 8.15.0 containers with the environment variables that the
project's GitHub Actions workflow expects. The example below names the containers `mysql` and
`elasticsearch` so the application can resolve them via hostname:

```bash
docker run --rm -d \
  --name mysql \
  -e MYSQL_DATABASE=diary_test \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql:5.7

docker run --rm -d \
  --name elasticsearch \
  -e discovery.type=single-node \
  -p 9200:9200 \
  docker.elastic.co/elasticsearch/elasticsearch:8.15.0
```

If you are running outside of containers, set the corresponding environment variables before
invoking Rails commands:

```bash
export MYSQL_DATABASE=diary_test
export MYSQL_ROOT_PASSWORD=password
export ELASTIC_HOST_URL=http://elasticsearch:9200
export ELASTICSEARCH_URL=$ELASTIC_HOST_URL
```

## 2. Prepare the Rails environment

Replicate the bootstrapping steps that CI performs so the database, fixtures, and Elasticsearch
index are ready:

```bash
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:fixtures:load FIXTURES_PATH=spec/fixtures
```

If Elasticsearch support is enabled, seed it before running specs:

```bash
bundle exec rake fromthepage:es:setup:init
bundle exec rake fromthepage:es:data:build
bundle exec rake fromthepage:es:data:reindex
```

## 3. Run lint and test jobs

Once services are available and the Rails environment is initialized, invoke the same commands the
workflow uses so Copilot Agent can read results and iterate on failures:

```bash
bundle exec rubocop        # or bundle exec rubocop -A for auto-corrections
xvfb-run -a bundle exec rspec spec
```

Running these steps from the shell provided to Copilot Agent allows it to execute the project's
linters, run the full RSpec suite, and apply fixes based on the output.
