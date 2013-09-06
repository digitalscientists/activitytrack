activity track
=============

Activity Track tracks user activity and stores it in ElasticSearch to personalize user experience across web, email and in-app notifications.

This gem is to be used as middleware in a Rails application. When installed it will intercept all requests on"/track_activity" or "/complement_note" and stores the data provided into elastic search in the tracked_activities index.

Each request should be supplied with the following params on the client: 
-  act_type - action name, used as an elasticsearch index type
-  params - any information about action, optionally can include the user identifier

If the params include the parameter "_id" it will be used as id of the appropriate document in Elastic Search.

Example: /track_activity request

    /track_activity?act_type=item_added&params[user_id]=1&params[item_id]=10&params[title]=awesome_title

The above request creates {'item_id': '10', 'title': 'awesome_title', 'user_id': '1'} in index /tracked_activies/item_added

Note that the records will persisted using a batch process. The batch is written to Elastic Search when 50 records are collected. This helps improve write performance on Elastic Search when writing a large number of records.

The "/complement_note" end point updates an existing record instead of creating a new one.

This request should also should be supplied with a query param and should follow a single level key-value structure.


Example of /complement_note request:

    /track_activity?act_type=item_added&query[user_id]=1&query[item_id]=10&params[color]=red

This request will search in /tracked_activities/item_added index for the document, with user_id=1 and item_id=10. The color param for that record is then set to 'red'.


To install, add the following to your rails application Gemfile:

    gem 'activity_tracker', :git => 'https://github.com/digitalscientists/activitytrack.git'

To run initializer
-------------

    rails g activity_tracker:install

Adds activity_tracker.rb to config/initializers of your application.

Config file supports the size of batches written to Elastic Search. Defaults to 50.

TODO
-------------

add ability to configure index_name.
add ability to change default paths for insert & update requests.


