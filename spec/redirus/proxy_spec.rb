require 'spec_helper'

describe Redirus::Proxy do
  let(:nginx_pid_file) { double('nginx pid file') }
  let(:config) {
    double('worker configuration',
      nginx_pid_file: 'nginx_pid_file'
    )
  }

  before do
    Redirus.stub(:config).and_return(config)
    allow(File).to receive(:open).with('nginx_pid_file').and_yield(nginx_pid_file)
    allow(nginx_pid_file).to receive(:read).and_return('123')
  end

  it 'invokes perform action' do
    allow(Process).to receive(:kill).with(:SIGHUP, 123)
    expect(subject).to receive(:perform_action).with('param', 123, :http)
    subject.perform('param', 123, :http)
  end

  it 'restarts nginx' do
    expect(Process).to receive(:kill).with(:SIGHUP, 123)
    subject.perform('param')
  end
end