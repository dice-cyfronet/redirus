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
bundler install

# Copy configuration
cp config.yml.example config.yml

# Customise redis configuration and nginx config files locations
edit config.yml
```

## Example Nginx configuration

```
worker_processes  2;

pid /path/to/nginx.pid;

events {
    worker_connections  1024;
}

http {
  # redirus http upstream
  include /generated/configuration/path/http_upstream.conf;
  # redirus https upstream
  include /generated/configuration/path/https_upstream.conf;

  server {
    listen 80;
    server_name my.server;

    root html;

    include /generated/configuration/path/http_proxy.conf;
  }

  server {
    listen 443 ssl;

    ssl_certificate     /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;
    ssl_protocols       SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    server_name my.server;

    root html;

    include /generated/configuration/path/https_proxy.conf;
  }
}
```

## Example config.yml

```
queue: site_prefix
redis_url: redis://localhost:6379
namespace: redirus
nginx:
  http:
    proxy: /generated/configuration/path/http_proxy.conf
    upstream: /generated/configuration/path/http_upstream.conf
  https:
    proxy: /generated/configuration/path/https_proxy.conf
    upstream: /generated/configuration/path/https_upstream.conf
  pid: /path/to/nginx.pid
```

## Run

```bash
bundle exec ./bin/run
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
