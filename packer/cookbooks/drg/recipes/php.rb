include_recipe 'php'
node.override['php']['directives'] = {
  'date.timezone' => 'GMT'
}

%w{php5-json php5-curl}.each do |pkg|
  package pkg do
    action :install
  end
end