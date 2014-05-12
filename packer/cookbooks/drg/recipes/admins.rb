node.override['authorization']['sudo']['groups'] = ["sudo"]
node.override['authorization']['sudo']['passwordless'] = true
include_recipe 'sudo'

# Jenkins User... jenkins-jclouds plugin will setup the rest
user "jenkins" do
  supports :manage_home => true
  home '/jenkins'
end

group "sudo" do
  action :modify
  members ["jenkins"]
  append true
end

# /etc/sudoers should be set for "sudo" instead of "wheel", but let's add them just in case
# group "wheel" do
#   action :modify
#   members ["jenkins"]
#   append true
# end
