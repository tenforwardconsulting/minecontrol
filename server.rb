require 'sinatra'
require 'aws'
require 'dnsimple'


def config
  if @config.nil?
    config_file = File.join(File.dirname(__FILE__), 'config.yml')
    if File.exist? config_file
      @config = YAML::load_file(config_file)
      puts "Starting up with configuration from file"
    else
      @config = {
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
        },
        'dns' => {
          'domain' => ENV['MC_DNS_DOMAIN'],
          'hostname' => ENV['MC_DNS_HOSTNAME'],
          'dnsimple' => {
            'domain_token' => ENV['MC_DNS_DNSIMPLE_DOMAIN_TOKEN']
          }
        }
      }
      puts "using config from environment"
    end
    raise "Bad config" unless @config['server'] && @config['aws']
  end

  @config
end

AWS.config(config['aws'])
DNSimple::Client.domain_token = config['dns']['dnsimple']['domain_token']
if (config['basic_auth'])
  use Rack::Auth::Basic, "MineControl" do |username, password|
    username == config['basic_auth']['username'] and password == config['basic_auth']['password']
  end
end


def dns_record
  domain = DNSimple::Domain.find(config['dns']['domain'])
  record = DNSimple::Record.all(domain).detect{ |x| x.name == config['dns']['hostname'] }
end

def aws_instance
  instance = AWS.ec2.instances[config['server']['instance_id']]
end

get '/' do
  
  @info = {
    status: aws_instance.status,
    ip_address: aws_instance.ip_address,
    dns: aws_instance.dns_name,
    launch_time: aws_instance.launch_time,
    zone: aws_instance.availability_zone,
    custom_dns: config['dns']['hostname'] + "." + config['dns']['domain'],
    custom_dns_ip: dns_record.content
  }

  haml :index
end

get '/stop' do 
  aws_instance.stop
  redirect '/'
end

get '/start' do 
  aws_instance.start
  redirect '/'
end

get '/set_dns' do 
  dns_record.content = aws_instance.ip_address
  dns_record.save
  redirect '/'
end




