require 'rubygems'
require 'oauth'
require 'json'

# make the consumer out of your secret and key
consumer_key = ARGV[0]
consumer_secret = ARGV[1]
consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
                               :site => "https://api.cloudkick.com",
                               :http_method => :get)

# make the access token from your consumer
access_token = OAuth::AccessToken.new(consumer)

# make a signed request!
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

p node_vals


checks.each do |id, status| 
  errors = status[:check_statuses].select{|key, s| s[:status] != 'Ok'}.collect {|key, s| s[:details]}
  p "Status #{node_vals[id.to_s]} #{errors}"
end
