require 'sinatra'
require 'aws'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == 'admin' and password == 'admin'
end

config = YAML::load_file(File.join(File.dirname(__FILE__), 'config.yml'))
AWS.config(config['aws'])
puts "Starting up with configuration: "
puts config

get '/' do
  instance = AWS.ec2.instances[config['server']['instance_id']]
  @info = {
    status: instance.status,
    ip_address: instance.ip_address,
    dns: instance.dns_name,
    launch_time: instance.launch_time,
    zone: instance.availability_zone
  }
  haml :index
end

get '/stop' do 
  instance = AWS.ec2.instances[config['server']['instance_id']]
  instance.stop
  redirect '/'
end

get '/start' do 
  instance = AWS.ec2.instances[config['server']['instance_id']]
  instance.start
  redirect '/'
end




