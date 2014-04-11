require 'sinatra'
require 'aws'

config_file = File.join(File.dirname(__FILE__), 'config.yml')
if File.exist? config_file
  config = YAML::load_file(config_file)
  puts "Starting up with configuration from file"
else
  config = {
    'basic_auth' => {
      'username' => ENV['MC_BASIC_AUTH_USERNAME'],
      'password' => ENV['MC_BASIC_AUTH_PASSWORD']
    },
    'server' => {
      'instance_id' => ENV['MC_SERVER_INSTANCE_ID']
    },
    'aws' => {
      'access_key_id' => ENV['MC_AWS_ACCESS_KEY_ID'],
      'secret_access_key' => ENV['MC_AWS_SECRET_ACCESS_KEY'],
      'region' => ENV['MC_AWS_REGION']
    }
  }
  puts "using config from environment"
end

raise "Bad config" unless config['server'] && config['aws']

AWS.config(config['aws'])

if (config['basic_auth'])
  use Rack::Auth::Basic, "MineControl" do |username, password|
    username == config['basic_auth']['username'] and password == config['basic_auth']['password']
  end
end

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




