module ActivityTracker
  class Railtie < Rails::Railtie
    initializer "activity_tracker.insert_middleware" do |app|
      app.config.middleware.use "ActivityTracker::App"
    end
  end
end
