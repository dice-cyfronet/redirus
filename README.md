# Redirus worker [![build status](https://secure.travis-ci.org/dice-cyfronet/redirus-worker.png)](https://travis-ci.org/dice-cyfronet/redirus-worker) [![Code Climate](https://codeclimate.com/github/dice-cyfronet/redirus-worker.png)](https://codeclimate.com/github/dice-cyfronet/redirus-worker) [![Dependency Status](https://gemnasium.com/dice-cyfronet/redirus-worker.png)](https://gemnasium.com/dice-cyfronet/redirus-worker) [![Coverage Status](https://coveralls.io/repos/dice-cyfronet/redirus-worker/badge.png?branch=master)](https://coveralls.io/r/dice-cyfronet/redirus-worker)

This is a worker repository. This code will only generate proxy configuration and next restart Nginx.

## Requirements

**Project is designed for Linux operating system.**

- Linux (tested on Ubuntu)
- Nginx

## Installation

```bash
# Get code
git clone https://github.com/dice-cyfronet/redirus-worker.git

# Enter code dir
cd redirus-worker

# Install dependencies
gem install bundler
bundle install

# Copy configuration
cp config.yml.example config.yml

# Customise redis configuration and nginx config files locations
edit config.yml
```

## Example config.yml

```
queues:
  - site_prefix
  - second_site_prefix

redis_url: redis://localhost:6379
namespace: redirus

nginx:
  configs_path: /path/to/dir/with/nginx/configs/
  pid: /path/to/nginx.pid
  http_template: |
    listen *:80;
  https_template: |
    listen *:443 ssl;
    ssl_certificate     /path/to/cert/dir/server.crt;
    ssl_certificate_key /path/to/cert/dir/server.key;
  config_template: |
    #{upstream}
    server {
      #{listen}
      server_name #{name}.my-domain.pl;
      server_tokens off;
      proxy_set_header X-Server-Address $scheme://#{name}.my-domain.pl;
      proxy_set_header Host $http_host;
      location / {
        proxy_pass http://#{upstream_name};
        #{properties}
      }
    }
  allowed_properties:
    - proxy_sent_timeout \d
    - proxy_read_timeout \d
```

Using `http_template`, `https_template`, `config_template` and `allowed_properties` you can customize how nginx configuration for every subdomain will looks like.

E.g. when redirection with following parameters should be created:

```ruby
Sidekiq::Client.push(
  'queue' => 'cyfronet',
  'class' => Redirus::Worker::AddProxy,
  'args' => ['subdomain', ['127.0.0.1:80'], :http, ["proxy_send_timeout 6000"]])
```

than `/nginx/sites-enabled/subdomain_http` file with subdomain nginx configuration is requested:

```
upstream subdomain_http {
  server 127.0.0.1:80;
}
server {
  listen *:8000;
  server_name subdomain.localhost;
  server_tokens off;
  location / {
    proxy_pass http://subdomain_http;
    proxy_send_timeout 6000;
  }
}
```

## Run

```bash
bundle exec ./bin/run
```

## Generating Add/Remove redirection requests

```ruby
# configure sidekiq client
Sidekiq.configure_client do |c|
  c.redis = { :namespace => Redirus::Worker.config.namespace, :url => Redirus::Worker.config.redis_url, queue: Redirus::Worker.config.queue }
end

# add new redirection
Sidekiq::Client.push('queue' => 'cyfronet', 'class' => Redirus::Worker::AddProxy, 'args' => ['subdomain', ['127.0.0.1'], :http, ["proxy_send_timeout 6000"]])

# remove redirection
Sidekiq::Client.push('queue' => 'cyfronet', 'class' => Redirus::Worker::RmProxy, 'args' => ['subdomain', :http])
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
