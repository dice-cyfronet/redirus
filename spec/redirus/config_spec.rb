require 'spec_helper'

describe Redirus::Config do

  context 'loading default values' do
    let(:config) { Redirus::Config.new 'nonexisting_config_file' }

    it 'returns redis config' do
      expect(config.queue).to eq 'default'
      expect(config.redis_url).to eq 'redis://localhost:6379'
      expect(config.namespace).to eq 'redirus'
    end

    it 'returns nginx files location' do
      expect(config.http_proxy_file).to eq 'http_proxy.conf'
      expect(config.http_upstream_file).to eq 'http_upstream.conf'
      expect(config.https_proxy_file).to eq 'https_proxy.conf'
      expect(config.https_upstream_file).to eq 'http_upstream.conf'
      expect(config.nginx_pid_file).to eq 'nginx.pid'
    end
  end

  context 'loading config from file' do
    let(:config) { Redirus::Config.new File.join(SPEC_DIR, 'resources', 'config.yml') }

    it 'returns redis config' do
      expect(config.queue).to eq 'configfile-default'
      expect(config.redis_url).to eq 'configfile-redis://localhost:6379'
      expect(config.namespace).to eq 'configfile-redirus'
    end

    it 'returns nginx files location' do
      expect(config.http_proxy_file).to eq 'configfile-http_proxy.conf'
      expect(config.http_upstream_file).to eq 'configfile-http_upstream.conf'
      expect(config.https_proxy_file).to eq 'configfile-https_proxy.conf'
      expect(config.https_upstream_file).to eq 'configfile-http_upstream.conf'
      expect(config.nginx_pid_file).to eq 'configfile-nginx.pid'
    end
  end
end