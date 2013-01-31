require 'net/http'
require 'uri'
require 'json'



net = Net::HTTP.new('localhost', 9200)


puts "creating:\n\n"

request = Net::HTTP::Post.new('/twitter/single/')
request.body = {'user_id' => 'user_iddd111'}.to_json
r = net.request request

r = JSON.parse(r.body)
puts r.inspect
id = r['_id']


puts "reading:\n\n"
puts "/twitter/single/#{id}"
request = Net::HTTP::Get.new("/twitter/single/#{id}")
r = net.request request
puts JSON.parse(r.body).inspect


puts "\n\nudating:\n\n"
puts "/twitter/single/#{id}"
request = Net::HTTP::Post.new("/twitter/single/#{id}/_update")
request.body = {
  'script' => "ctx._source.new_data = new_data; ctx._source.user_id = user_id",
  'params' => {
    'user_id' => 'new user id 21212',
    'new_data' => 'New_dataaa'
  }

}.to_json
r = net.request request
puts JSON.parse(r.body).inspect


puts "reading:\n\n"
puts "/twitter/single/#{id}"
request = Net::HTTP::Get.new("/twitter/single/#{id}")
r = net.request request
puts JSON.parse(r.body).inspect

puts r.headers
