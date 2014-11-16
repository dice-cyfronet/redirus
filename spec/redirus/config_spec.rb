require 'spec_helper'

describe Redirus::Config do

  context 'loading default values' do
    let(:config) { Redirus::Config.new('nonexisting_config_file') }

    it 'returns redis config' do
      expect(config.queues).to eq ['default']
      expect(config.redis_url).to eq 'redis://localhost:6379'
      expect(config.namespace).to eq 'redirus'
    end

    it 'returns nginx files location' do
      expect(config.nginx_pid_file).to eq 'nginx.pid'
      expect(config.configs_path).to eq 'sites-enabled'
      expect(config.http_template).to eq 'http.conf.erb'
      expect(config.https_template).to start_with 'https.conf.erb'
      expect(config.allowed_properties).to eq []
    end
  end

  context 'loading config from file' do
    let(:config) do
      Redirus::Config.new(File.join(SPEC_DIR, 'resources', 'config.yml'))
    end

    it 'returns redis config' do
      expect(config.queues).to eq ['first', 'second']
      expect(config.redis_url).to eq 'configfile-redis://localhost:6379'
      expect(config.namespace).to eq 'configfile-redirus'
    end

    it 'returns nginx files location' do
      expect(config.nginx_pid_file).to eq 'configfile-nginx.pid'
      expect(config.configs_path).to eq 'configfile-sites-enabled'
      expect(config.http_template).to eq '/path/to/http/tmpl'
      expect(config.https_template).to start_with '/path/to/https/tmpl'
      expect(config.allowed_properties).to eq ['proxy_send_timeout \d', 'proxy_read_timeout \d']
    end
  end
end