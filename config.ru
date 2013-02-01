require 'rack'
require 'rack/lobster'
require File.expand_path(File.dirname(__FILE__) + '/lib/activity_tracker')

use Rack::MonetaStore, :Memory
use ActivityTracker::App
run Proc.new {|env| [200, {'Content-Type' => 'text/html'}, ['
  <ul>
    <li>
      <a href="/track_activity?act_type=abs_act&user_id=1&params[title]=item_title&params[_id]=123" >save record</a>
    </li>
    <li>
      <a href="/complement_note?act_type=abs_act&user_id=1&params[color]=red&query[_id]=123" >update record</a>
    </li>
  </ul>
']]}
#run ActivityTracker.new

