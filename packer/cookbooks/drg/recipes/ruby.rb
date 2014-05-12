if node[:instance_role] == 'vagrant'
  # Ideally would be group_users, but see https://github.com/RiotGames/rbenv-cookbook/issues/44
  # node.override[:rbenv][:group_users] = ['vagrant']
  node.override[:rbenv][:user] = 'vagrant'
else
  node.override[:rbenv][:user] = 'jenkins'
end

include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"
include_recipe "rbenv::rbenv_vars"

global_ruby = "2.1.0"
other_rubies = ["1.9.3-p448", "2.0.0-p353"]

rbenv_ruby global_ruby do
  ruby_version global_ruby
  global true
end

other_rubies.each do |version|
  rbenv_ruby version
end

other_rubies.push(global_ruby).each do |version|
  rbenv_gem "bundler" do
    ruby_version version
  end
end
