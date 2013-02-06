require 'net/http'
require 'uri'

net = Net::HTTP.new('localhost', 9200)

request = Net::HTTP::Delete.new('/tracked_activities')
net.request request
