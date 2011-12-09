require 'rubygems'
require 'oauth'
require 'json'
require 'sinatra'

config = YAML.load_file('config.yml')
consumer = OAuth::Consumer.new(config['consumer_key'], config['consumer_secret'],
                               :site => "https://api.cloudkick.com",
                               :http_method => :get)

def map i
 [i[:id], { 
          :tags => i[:tags].collect{|x| x[:name]},
          :ip => i[:ipaddress],
          :instance_id => i[:details][:instanceId]
        }]
end

get "/" do
  access_token = OAuth::AccessToken.new(consumer)
  req = access_token.get("/2.0/nodes")
  nodes = JSON.parse(req.response.body, :symbolize_names => true)
  mapping =  nodes[:items].collect{ |i| map(i)}
  node_vals = Hash[*mapping.flatten]

  req = access_token.get("/2.0/status/nodes?overall_check_statuses=Warning&overall_check_statuses=Error")

  case req.response.code
  when "200"
    checks = JSON.parse(req.response.body, :symbolize_names => true)
  else
    puts "error: #{req.inspect}"
  end

  status = checks.collect do |id, status| 
    [node_vals[id.to_s], status[:check_statuses].select{|key, s| s[:status] != 'Ok'}.collect {|key, s| s[:details]}.uniq ]
  end

  haml :index, :locals => {:status => status}, :format => :html5
end
