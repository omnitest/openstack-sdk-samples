include_recipe 'apt'

ssh_known_hosts_entry 'github.com'

node.force_default[:dnsmasq][:dns] = {
  # 'no-poll' => nil,
  # 'no-resolv' => nil,
  'bind-interfaces' => nil,
  'server' => '127.0.0.1',
  'address' => '/dev/127.0.0.1'
}

include_recipe 'dnsmasq'
