execute "reload-haproxy" do
  command "/etc/init.d/haproxy reload"
  action :nothing
end

haproxy_http_port = (app = node.apps.detect {|a| a.metadata?(:haproxy_http_port) } and app.metadata?(:haproxy_http_port)) || 80
haproxy_https_port = (app = node.apps.detect {|a| a.metadata?(:haproxy_https_port) } and app.metadata?(:haproxy_https_port)) || 443

# CC-52
# Add http check for accounts with adequate settings in their dna metadata

haproxy_httpchk_path = (app = node.apps.detect {|a| a.metadata?(:haproxy_httpchk_path) } and app.metadata?(:haproxy_httpchk_path))
haproxy_httpchk_host = (app = node.apps.detect {|a| a.metadata?(:haproxy_httpchk_host) } and app.metadata?(:haproxy_httpchk_host))

execute "Generate HAProcy keep file" do
  command "touch /etc/keep.haproxy.cfg"
  action :run
end

template "/etc/haproxy.cfg" do
  owner 'root'
  group 'root'
  mode 0644
  source "haproxy.cfg.erb"
  variables({
    :backends => node.environment.app_servers,
    :haproxy_user => node[:haproxy][:username],
    :haproxy_pass => node[:haproxy][:password],
    :http_bind_port => haproxy_http_port,
    :https_bind_port => haproxy_https_port,
    :httpchk_host => haproxy_httpchk_host,
    :httpchk_path => haproxy_httpchk_path
  })

  # We need to reload to activate any changes to the config
  # but delay it as haproxy may not be installed yet
  notifies :run, resources(:execute => 'reload-haproxy'), :delayed
end
