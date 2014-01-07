require 'spec_helper'

describe Redirus::Worker::RmProxy do
  let(:proxy_file) { double('proxy file') }
  let(:nginx_pid_file) { double('nginx pid file') }
  let(:config) {
    double('worker configuration',
      configs_path: 'configs_base_path',
      nginx_pid_file: 'nginx_pid_file'
    )
  }

  before do
    Redirus::Worker.stub(:config).and_return(config)
    allow(File).to receive(:open).with('nginx_pid_file').and_yield(nginx_pid_file)
    allow(nginx_pid_file).to receive(:read).and_return('123')
    allow(Process).to receive(:kill).with(:SIGHUP, 123)
    allow(File).to receive(:delete)
  end


  context 'when http redirection' do
    before { subject.perform('subdomain', :http) }

    it 'removes redirection configuration file' do
      expect(File).to have_received(:delete).with('configs_base_path/subdomain_http')
    end

    it 'restarts nginx' do
      expect(Process).to have_received(:kill).with(:SIGHUP, 123)
    end
  end

  context 'when https redirection' do
    before { subject.perform('subdomain', :https) }

    it 'removes redirection configuration file' do
      expect(File).to have_received(:delete).with('configs_base_path/subdomain_https')
    end
  end
end