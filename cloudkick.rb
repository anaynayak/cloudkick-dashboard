require 'rubygems'
require 'oauth'
require 'json'
require 'sinatra'
require 'ohm'

class Kicker < Ohm::Model
  attribute :consumer_key
  attribute :consumer_secret
  attribute :token
  index :token
end

def map i
 [i[:id], { 
          :tags => i[:tags].collect{|x| x[:name]},
          :ip => i[:ipaddress],
          :instance_id => i[:details][:instanceId]
        }]
end
class Cloudkick < Sinatra::Base
  configure :development do
    enable :logging
    Ohm.connect
  end
  configure :production do
    enable :logging
    Ohm.connect(:url => ENV["REDISTOGO_URL"])
  end
  get '/' do
    haml :index, :format => :html5
  end
  get '/:token' do
    @kicker = Kicker.find(:token => params[:token]).to_a.first
    consumer = OAuth::Consumer.new(@kicker.consumer_key, @kicker.consumer_secret, :site => "https://api.cloudkick.com", :http_method => :get)
    access_token = OAuth::AccessToken.new(consumer)
    status = get_status(access_token)
    haml :status, :locals => {:status => status}, :format => :html5
  end
  post '/register' do
    @kicker = Kicker.create(:consumer_key => params['key'], :consumer_secret => params['secret'], :token => rand(36**8).to_s(36))
    redirect to ("/#{@kicker.token}")
  end
end

def get_status(access_token)
  req = access_token.get("/2.0/nodes")
  return [] if req.response.code != 200
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

  checks.collect do |id, status| 
    [node_vals[id.to_s].merge(:overall_status => status[:overall_check_statuses].downcase), status[:check_statuses].select{|key, s| s[:status] != 'Ok'}.collect {|key, s| s[:details]}.uniq ]
  end
end
