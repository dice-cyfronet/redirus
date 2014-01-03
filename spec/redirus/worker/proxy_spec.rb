require 'spec_helper'

describe Redirus::Worker::Proxy do
  describe '.generator' do
    context "when overridden" do
      let(:generator) { double("mocked generator") }
      before          { Redirus::Worker::Proxy.generator = generator }
      it              { expect(Redirus::Worker::Proxy.generator).to eq(generator) }
    end

    context "when not set" do
      before { Redirus::Worker::Proxy.generator = nil }
      it     { expect(Redirus::Worker::Proxy.generator).to eq(Redirus::Worker::NginxConfigGenerator) }
    end
  end

  context 'nginx configuration generator' do
    let(:config) {
      double('worker configuration',
        http_proxy_file: 'http_proxy_file',
        http_upstream_file: 'http_upstream_file',
        https_proxy_file: 'https_proxy_file',
        https_upstream_file: 'https_upstream_file',
        nginx_pid_file: 'nginx_pid_file'
      )
    }
    let(:generator) {
      double('nginx config generator', generate: {
        http:  { proxy: 'http proxy',  upstream: 'http upstream' },
        https: { proxy: 'https proxy', upstream: 'https upstream' }
      })
    }
    let(:generator_class) { double('nginx config generator class', new: generator) }
    let(:http_proxy_file) { double('http proxy file') }
    let(:http_upstream_file) { double('http upstream file') }
    let(:https_proxy_file) { double('https proxy file') }
    let(:https_upstream_file) { double('https upstream file') }
    let(:nginx_pid_file) { double('https upstream file') }

    let!(:process) { Process.stub(:kill) }

    before {
      File.stub(:open) do |file_name, mode|
        case file_name
          when 'http_proxy_file'     then http_proxy_file
          when 'http_upstream_file'  then http_upstream_file
          when 'https_proxy_file'    then https_proxy_file
          when 'https_upstream_file' then https_upstream_file
          when 'nginx_pid_file'      then nginx_pid_file
        end
      end

      Redirus::Worker.stub(:config).and_return(config)
      Redirus::Worker::Proxy.generator = generator_class
    }

    after { Redirus::Worker::Proxy.generator = nil }

    it 'uses generator to create configuration' do
      expect(generator_class).to receive(:new).with('proxies', 'properties')
      expect(generator).to receive(:generate)
      subject.perform('proxies', 'properties')
    end

    it 'generates http proxy configuration' do
      allow(File).to receive(:open).with('http_proxy_file', 'w').and_yield(http_proxy_file)
      expect(http_proxy_file).to receive(:write).with(generator.generate[:http][:proxy])

      subject.perform('proxies', 'properties')
    end

    it 'generates http upstream configuration' do
      allow(File).to receive(:open).with('http_upstream_file', 'w').and_yield(http_upstream_file)
      expect(http_upstream_file).to receive(:write).with(generator.generate[:http][:upstream])

      subject.perform('proxies', 'properties')
    end

    it 'generates https proxy configuration' do
      allow(File).to receive(:open).with('https_proxy_file', 'w').and_yield(https_proxy_file)
      expect(https_proxy_file).to receive(:write).with(generator.generate[:https][:proxy])

      subject.perform('proxies', 'properties')
    end

    it 'generates https upstream configuration' do
      allow(File).to receive(:open).with('https_upstream_file', 'w').and_yield(https_upstream_file)
      expect(https_upstream_file).to receive(:write).with(generator.generate[:https][:upstream])

      subject.perform('proxies', 'properties')
    end

    it 'restarts nginx' do
      allow(nginx_pid_file).to receive(:read).and_return('123')
      allow(File).to receive(:open).with('nginx_pid_file').and_yield(nginx_pid_file)

      expect(Process).to receive(:kill).with(:SIGHUP, 123)

      subject.perform('proxies', 'properties')
    end
  end
end