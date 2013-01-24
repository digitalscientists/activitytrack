module ActivityTracker
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      desc 'Creates a ActivityTracker initializer'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/activity_tracker.rb'
      end

    end
  end
end
