require 'rails/generators'
require 'rails/generators/migration'

module DevhagoHealthCheck
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Copies the DevhagoHealthCheck initializer and (optionally) migrations to the host application.'

      def copy_initializer
        template 'devhago_health_check_initializer.rb', 'config/initializers/devhago_health_check.rb'
      end

      def copy_migrations
        migration_template 'create_health_check_snapshots.rb', 'db/migrate/create_health_check_snapshots.rb'
      end

      # Implement the required interface for migration_template
      def self.next_migration_number(_dirname)
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end
    end
  end
end
