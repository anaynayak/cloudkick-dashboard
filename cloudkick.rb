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
req = access_token.get("/1.0/query/nodes")

case req.response.code
when "200"
  checks = JSON.parse(req.response.body, :symbolize_names => true)
else
  puts "error: #{req.inspect}"
end

p checks
