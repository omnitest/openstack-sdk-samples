node.override["go"]["version"] = "1.1.1"
node.override["go"]["filename"] = "go#{node["go"]["version"]}.#{node["os"]}-#{node["go"]["platform"]}.tar.gz"
node.override['go']['url'] = "http://go.googlecode.com/files/#{node["go"]["filename"]}"
include_recipe 'golang'
