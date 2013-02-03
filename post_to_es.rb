require 'net/http'
require 'uri'
require 'json'

puts "\n"

def benchmark &blok
  start_time = Time.now
  puts "Start: #{start_time}"
  yield
  end_time = Time.now
  puts "End: #{end_time}"

  duration = end_time - start_time
  puts "Duration: #{duration}"
end

COUNT = 50

#clearing indexes
net = Net::HTTP.new('localhost', 9200)

request = Net::HTTP::Delete.new('/tracked_activities')
net.request request

request = Net::HTTP::Delete.new('/twitter/single/')
net.request request


request = Net::HTTP::Delete.new('/twitter/bulk/')
net.request request

puts "Storing #{COUNT} actions with single request each\n"

benchmark do
  (1..COUNT).each do |i|
    request = Net::HTTP::Post.new('/twitter/single/')
    request.body = {'user_id' => i.to_s}.to_json
    net.request request
  end
end
puts "\n\n"
puts "Storing #{COUNT} actions with bulk request\n"




batch = (1..COUNT).to_a
benchmark do

  batch = batch.map do |i| 
    [
      {'index' => {'_index' => 'twitter', '_type' => 'bulk',}}.to_json,
      {'user_id' => i.to_s}.to_json
    ]
  end.flatten.join("\n")


  net = Net::HTTP.new('localhost', 9200)
  request = Net::HTTP::Post.new('/twitter/bulk/_bulk')
  request.body = batch
  net.request request
end



