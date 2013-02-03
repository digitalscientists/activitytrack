require 'rack'

load File.expand_path(File.dirname(__FILE__) + '/lib/activity_tracker.rb')


class AppLoader
  def initialize app
    @app = app
  end

  def call env
    load File.expand_path(File.dirname(__FILE__) + '/lib/activity_tracker.rb')
    @app.call env
  end
end

use AppLoader
use Rack::MonetaStore, :Memory
use ActivityTracker::App
run Proc.new {|env| [200, {'Content-Type' => 'text/html'}, ['
  <ul>
    <li>
      <a href="/track_activity?act_type=abs_act&params[user_id]=1&params[title]=item_title&params[item_id]=123" >save record</a>
    </li>
    <li>
      <a href="/complement_note?act_type=abs_act&query[user_id]=1&params[color]=red&query[item_id]=123" >update record</a>
    </li>
  </ul>
']]}
#run ActivityTracker.new

