require 'spec_helper'

describe Redirus::Worker::Proxy, 'nginx configuration generation' do
  let(:worker) { Redirus::Worker::Proxy.new }

  context 'when proxies list is empty' do
    it 'generates empty configurations when no redirections' do

    end
  end
end