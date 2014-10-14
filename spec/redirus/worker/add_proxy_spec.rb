require 'spec_helper'

describe Redirus::Worker::AddProxy do
  let(:proxy_file) { double('proxy file') }
  let(:nginx_pid_file) { double('nginx pid file') }
  let(:config) {
    double('worker configuration',
      configs_path: 'configs_base_path',
      http_template: 'http_section',
      https_template: 'https_section',
      base_server_name: 'localhost',
      config_template: %q[#{upstream}
        server {
          #{listen}
          server_name #{name}.my.server.pl;
          location / {
            proxy_pass http://#{upstream_name};
            #{properties}
          }
        }
      ],
      allowed_properties: ['proxy_send_timeout \d', 'proxy_read_timeout \d'],
      nginx_pid_file: 'nginx_pid_file'
    )
  }

  before do
    allow(Redirus).to receive(:config).and_return(config)
    allow(File).to receive(:open).with('nginx_pid_file').and_yield(nginx_pid_file)
    allow(nginx_pid_file).to receive(:read).and_return('123')
    allow(Process).to receive(:kill)
  end

  context 'when http redirection is required' do
    before do
      allow(File).to receive(:open).with('configs_base_path/subdomain_http', 'w').and_yield(proxy_file)
      allow(proxy_file).to receive(:write)
      subject.perform('subdomain', ['10.100.10.112:80', '10.100.10.113:80'], :http)
    end

    it 'sets http listen section' do
      expect(proxy_file).to have_received(:write).with(/.*http_section.*/)
    end

    it 'sets http upstream name in proxy pass section' do
      expect(proxy_file).to have_received(:write).with(/.*proxy_pass http:\/\/subdomain_http;.*/)
    end

    it 'has http upstream section with 2 upstream servers' do
      expect(proxy_file).to have_received(:write).with(/.*upstream subdomain_http {\n\s*server 10.100.10.112:80;\n\s*server 10.100.10.113:80;\n\s*}.*/)
    end

    it 'sets subdomain.my.server.pl server name' do
      expect(proxy_file).to have_received(:write).with(/.*subdomain\.my\.server\.pl;.*/)
    end

    it 'restarts nginx' do
      expect(Process).to have_received(:kill).with(:SIGHUP, 123)
    end
  end

  context 'when https redirection is required' do
    before do
      allow(File).to receive(:open).with('configs_base_path/subdomain_https', 'w').and_yield(proxy_file)
      allow(proxy_file).to receive(:write)
      subject.perform('subdomain', ['10.100.10.112:80'], :https)
    end

    it 'sets https listen section' do
      expect(proxy_file).to have_received(:write).with(/.*https_section.*/)
    end

    it 'sets https upstream name in proxy pass section' do
      expect(proxy_file).to have_received(:write).with(/.*proxy_pass http:\/\/subdomain_https;.*/)
    end

    it 'has https upstream section with upstream server' do
      expect(proxy_file).to have_received(:write).with(/.*upstream subdomain_https {\n\s*server 10.100.10.112:80;\n\s*}.*/)
    end
  end

  context 'when redirection with properties is required' do
    before do
      allow(File).to receive(:open).with('configs_base_path/subdomain_http', 'w').and_yield(proxy_file)
      allow(proxy_file).to receive(:write)
    end

    it 'writes static properties into location section' do
      expect(proxy_file).to receive(:write).with(/location \/ {\s*.*\s*proxy_send_timeout 600;\s*proxy_read_timeout 600;\s*}/)

      subject.perform('subdomain', ['10.100.10.112:80'], :http, ['proxy_send_timeout 600', 'proxy_read_timeout 600'])
    end

    it 'discard not allowed properties' do
      expect(proxy_file).to_not receive(:write).with(/not allowed property/)

      subject.perform('subdomain', ['10.100.10.112:80'], :http, ['not allowed property'])
    end
  end
end