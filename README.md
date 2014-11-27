# Redirus [![build status](https://secure.travis-ci.org/dice-cyfronet/redirus.png)](https://travis-ci.org/dice-cyfronet/redirus) [![Code Climate](https://codeclimate.com/github/dice-cyfronet/redirus.png)](https://codeclimate.com/github/dice-cyfronet/redirus) [![Dependency Status](https://gemnasium.com/dice-cyfronet/redirus.png)](https://gemnasium.com/dice-cyfronet/redirus) [![Coverage Status](https://coveralls.io/repos/dice-cyfronet/redirus/badge.png?branch=master)](https://coveralls.io/r/dice-cyfronet/redirus)

The redirus is responsible for creating/deleting subdomain redirections.
It is done by generating the appropriate nginx configurations and
reloading nginx server.

## Requirements

**This project is designed for Linux operating systems.**

- Linux (tested on Ubuntu)
- Nginx
- Ruby 2.0+
- Redis (can be installed on separate server)

## Packages / Dependencies

Install the required packages (needed to compile Ruby and nginx):

```
sudo apt-get update

apt-get install autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev g++ make libpcre3 libpcre3-dev libssl-dev
```

## Ruby

You can use ruby installed by ruby version managers such as [RVM](http://rvm.io/)
or [rbenv](https://github.com/sstephenson/rbenv), or install it globally from
sources. The following manual presents global installation.

Remove the old Ruby 1.8 if present

```
sudo apt-get remove ruby1.8
```

Download Ruby and compile it:

```
mkdir /tmp/ruby && cd /tmp/ruby
curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar xz
cd ruby-2.1.2
./configure --disable-install-rdoc
make
sudo make install
```

## Nginx installation

Download and compile nginx:

```
mkdir -p /tmp/nginx && cd /tmp/nginx
curl http://nginx.org/download/nginx-1.7.4.tar.gz | tar xz
cd nginx-1.7.4
./configure --with-http_ssl_module --prefix=/nginx/installation/path
make
make install
```

Update nginx configuration:

```
edit /nginx/installation/path/conf/nginx.conf
```

the simplest configuration may look as follows:

```
worker_processes  1;

pid /nginx/installation/path/nginx.pid;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    types_hash_max_size 2048;
    server_names_hash_bucket_size  128;

    include /path/to/generated/nginx/configurations/*;
}
```
Two elements from presented configuration need to be customized:
+ `/nginx/installation/path/nginx.pid` file where nginx pid will be written.
+ `/path/to/generated/nginx/configurations/*` path to the place where redirus
worker will be generating configurations specific to registered redirections. `*`
is necessary at the end in order to load all configurations from this directory.

If  nginx is to bind to a low-numbered port, e.g. port 80,
the following command needs to be executed as root:

```
# package required to invoke setcap
apt-get install libcap2-bin

# allow nginx to bind into low-numbered port
setcap 'cap_net_bind_service=+ep' /path/to/nginx/sbin/nginx
```

## Self signed certificate

In production environment valid certificate (with `*` in CN section) signed by trusted organization should be used. If you don't have such certificate than
you can generate self signed certificate:

```
mkdir /usr/share/ssl/certs/my-domain.pl
cd /usr/share/ssl/certs/my-domain.pl
(umask 077 && touch host.key host.cert host.info host.pem)
openssl genrsa 2048 > host.key
openssl req -new -x509 -nodes -sha1 -days 3650 -key host.key > host.cert
...[enter *.my-domain.pl for the Common Name]...
openssl x509 -noout -fingerprint -text < host.cert > host.info
cat host.cert host.key > host.pem
chmod 400 host.key host.pem
```

## Redirus worker installation

```bash
# install redirus
gem install redirus

# Generate inital redirus and nginx configuration
redirus-init

# Customise redis configuration and nginx config files locations
edit config.yml
edit http.erb.conf
edit https.erb.conf
```

## Example config.yml

```yaml
queues:
  - site_prefix
  - second_site_prefix

redis_url: redis://localhost:6379
namespace: redirus

nginx:
  configs_path: /path/to/generated/nginx/configurations/
  pid: /nginx/installation/path/nginx.pid
  http_template: /path/to/http/nginx/config/template
  https_template: /path/to/https/nginx/config/template
  allowed_properties:
    - proxy_sent_timeout \d
    - proxy_read_timeout \d
```

Some elements from presented configuration need to be customized:
+ `/path/to/generated/nginx/configurations/` is the location where configuration
specific for concrete redirection will be created. Value of this path **need** to
be the same as in nginx configuration file.
+ `/nginx/installation/path/nginx.pid` is a file containing nginx pid. To this pid
`SIGHUP` signal will be sent, which will triggers nginx configuration reload.
+ `allowed_properties` is used to define allowed location parameters which can be
passed in the generated configuration. Regular expressions can be used here.

## Example `http.erb.conf` and `https.erb.conf`

`http.erb.conf` used to create `http` redirections:

```
upstream <%= @name %>_http {
<% if @options[:load_balancing] == :ip_hash -%>
  ip_hash;
<% end -%>
<% for worker in @workers -%>
  server <%= worker %>;
<% end -%>
}

server {
  listen 127.0.0.1:80;
  server_name <%= @name %>.localhost;
  location / {
    proxy_pass http://<%= @name %>_http;
<% for property in @location_properties -%>
    <%= property %>;
<% end -%>
  }
}
```

`https.erb.conf` used to create `https` redirections:

```
upstream <%= @name %>_https {
<% for worker in @workers -%>
  server <%= worker %>;
<% end -%>
}

server {
  listen 127.0.0.1:443 ssl;
  server_name <%= @name %>.localhost;

  ssl_certificate     /path/to/cert/dir/server.crt;
  ssl_certificate_key /path/to/cert/dir/server.key;
  ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;

  location / {
    proxy_pass http://<%= @name %>_https;
<% for property in @location_properties -%>
    <%= property %>;
<% end -%>
  }
}
```

In presented templates following dynamic elements are used:

  - `@name` - redirection name used as a url prefix
  - `@workers` - list of upstream addresses in following format `ip:port`
  - `@location_properties` - list of location properties
    (possible properties can be limitted using `allowed_properties` section
    in `config.yml` file)
  - `@options` - other properties passed by the redirus client,
    can be used e.g. to allow sticky session configuration like presented in
    `http.erb.conf`

For example - when a redirection with the following parameters is requested:

```ruby
Sidekiq::Client.push(
  'queue' => 'cyfronet',
  'class' => Redirus::Worker::AddProxy,
  'args' => [
              'subdomain', ['127.0.0.1:80'], :http,
              ["proxy_send_timeout 6000"],
              { load_balancing: :ip_hash }
            ]
  )
```

...then the following `/nginx/sites-enabled/subdomain_http` subdomain config file
will be created:

```
upstream subdomain_http {
  ip_hash;
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

**NOTE:** It is redirus administrator role to prepare `http` and `https`
templates in such a way that generated configuration will be valid.
If at least one nginx configuration will be invalid then nginx will fail to
reboot.

## Redirus generator

By running following command:

```
redirus-init
```

set of `redirus` and `nginx` configuration files will be created.
You can customize generated files by providing additional `redirus-init`
parameters.

See `redirus-init -h` for details.

## Run redirus

```bash
redirus -c redirus_configuration_path
```

When no configuration path is given than redirus tries to load configuration from `config.yml` located in current dir.

See `redirus -h` for details.

## Run redirus client

```
redirus-client -c config.yml -a add -t http my_redirection 10.100.0.1:80,10.100.0.2:80
redirus-client -c config.yml -a rm -t http my_redirection
```

See `redirus-client -h` for details.

## Starting using upstart

**NOTE**: presented configuration was tested on Ubuntu 14.04

Copy upstart configuration files:

```
cd redirus-worker-directory
mkdir -p ${HOME}/.config/upstart
cd ${HOME}/.config/upstart

curl -L --progress https://raw.githubusercontent.com/dice-cyfronet/redirus/master/support/upstart/redirus.conf > redirus.conf
curl -L --progress https://raw.githubusercontent.com/dice-cyfronet/redirus/master/support/upstart/redirus-sidekiq.conf > redirus-sidekiq.conf
curl -L --progress https://raw.githubusercontent.com/dice-cyfronet/redirus/master/support/upstart/redirus-nginx.conf > redirus-nginx.conf

# Specify user name, path under which the redirus worker is installed and
# the location of the nginx configuration directory to be created:
editor ${HOME}/.config/upstart/redirus.conf

# Similar as above, plus if you are using ruby version manager - uncomment and
# customize the appropriate section for rbenv or rvm
editor ${HOME}/.config/upstart/redirus-sidekiq-1.conf

# Update path to nginx
editor ${HOME}/.config/upstart/redirus-nginx.conf
```
Now you should be able to start/stop/restart redirus using the
following commands:

```
initctl start redirus
initctl stop redirus
initctl restart redirus
```

## Generating Add/Remove redirection requests from ruby code

```ruby
require 'rubygems'
require 'redirus/worker'
require 'redirus/worker/add_proxy'
require 'redirus/worker/rm_proxy'

# configure sidekiq client
Sidekiq.configure_client do |c|
  c.redis = {
    namespace: Redirus::Worker.config.namespace,
    url: Redirus::Worker.config.redis_url,
    queue: Redirus::Worker.config.queues.first
  }
end

# add new redirection
Sidekiq::Client.push(
  'queue' => Redirus::Worker.config.queues.first,
  'class' => Redirus::Worker::AddProxy,
  'args' => [
              'subdomain', ['127.0.0.1'], :http,
              ["proxy_send_timeout 6000"],
              { load_balancing: :ip_hash }
            ]
)

# remove redirection
Sidekiq::Client.push(
  'queue' => Redirus::Worker.config.queues.first,
  'class' => Redirus::Worker::RmProxy,
  'args' => ['subdomain', :http])
```

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request
