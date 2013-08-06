RSpec::Matchers.define :conf_be_empty do
  match do |actual|
    actual[:proxy] == ''
    actual[:upstream] == ''
  end
end

RSpec::Matchers.define :have_config do |path, proxy_pass|
  match do |actual|
    actual[:proxy] =~ /location "#{excape(path)}" {\n  proxy_pass http:\/\/#{proxy_pass}\/;/
  end

  def excape(path)
    path.gsub('/', '\/')
  end
end

RSpec::Matchers.define :have_upstream_config do |proxy_pass, workers|
  match do |actual|
    expected = <<-ENTRY
      upstream #{proxy_pass} {
        #{workers_config(workers)}
      }
    ENTRY
    actual[:upstream].gsub(/[\s\n]/, "").include? expected.gsub(/[\s\n]/, "")
  end

  def workers_config(workers)
    workers.collect do |worker|
      "server #{worker};\n"
    end.join
  end
end

RSpec::Matchers.define :have_property do |path, property|
  match do |actual|

    actual[:proxy] =~ /location \"#{excape(path)}\" {(\n.+)*#{excape(property)};/
  end

  def excape(path)
    path.gsub('/', '\/')
  end
end