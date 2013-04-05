activity track
=============

Gem to track user activity and store it in ElasticSearch and use it to personalize user experience.

This gem is suposed to be used as middleware with rails. When installed it will intercept all requests which pathes are strarting from "/track_activity" or "/complement_note" and will store data provided with requests into elastic search in tracked_activities index.

Each request should be supplied with params: 
-  act_type - action name, this is used as elasticsearch index type
-  params - any information about action which optionly can include user identifier

NOTE! If params will include parameter "_id" it will be used as id of apropriate document in ES

request on "/track_activity" will create new document 

example of /track_activity request:

    /track_activity?act_type=item_added&params[user_id]=1&params[item_id]=10&params[title]=awesome_title

this will create {'item_id': '10', 'title': 'awesome_title', 'user_id': '1'} in index /tracked_activies/item_added

note that record will not be created instantly. It will be accumulated to batch. When batch will consist of 50 records, they will be pushed ot elasicsarch via single request

request on "/complement_note" will find and update specific record.

/complent_note also should be supplied with query param. This parametr shoulbe single level key-value structure.


example of /complement_note request:

    /track_activity?act_type=item_added&query[user_id]=1&query[item_id]=10&params[color]=red

this will search in /tracked_activities/item_added index for document with user_id=1 and item_id=10. Then it will set color param to 'red'.


To install add to your rails application Gemfile:

    gem 'activity_tracker', :git => 'https://github.com/digitalscientists/activitytrack.git'

To generate initializer
-------------

    rails g activity_tracker:install

this will add activity_tracker.rb to config/initializers of your application.

there you can set size of batches which is set to 50 by default

TODO
-------------

add ability to configure index_name.
add ability to change default pathes for inserta nad update requests.


