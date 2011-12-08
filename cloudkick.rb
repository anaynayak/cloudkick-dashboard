require 'rubygems'
require 'oauth'
require 'json'
require 'sinatra'

config = YAML.load_file('config.yml')
# make the consumer out of your secret and key
consumer = OAuth::Consumer.new(config['consumer_key'], config['consumer_secret'],
                               :site => "https://api.cloudkick.com",
                               :http_method => :get)

get "/" do
  access_token = OAuth::AccessToken.new(consumer)
  req = access_token.get("/2.0/nodes")
  nodes = JSON.parse(req.response.body, :symbolize_names => true)
  mapping =  nodes[:items].collect{ |i| [i[:id],"#{i[:tags].collect{|x| x[:name]}} || #{i[:groups]} ||  #{i[:ipaddress]} || #{i[:details][:instanceId]}"]}
  node_vals = Hash[*mapping.flatten]

  req = access_token.get("/2.0/status/nodes?overall_check_statuses=Warning&overall_check_statuses=Error")

  case req.response.code
  when "200"
    checks = JSON.parse(req.response.body, :symbolize_names => true)
  else
    puts "error: #{req.inspect}"
  end

  status = checks.collect do |id, status| 
    errors = status[:check_statuses].select{|key, s| s[:status] != 'Ok'}.collect {|key, s| s[:details]}
    "Status #{node_vals[id.to_s]} #{errors}"
  end
  p status.join ","
end
