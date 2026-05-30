require 'rails/generators'

module DevhagoHealthCheck
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Copies the DevhagoHealthCheck initializer to the host application. ' \
           'The engine migration is appended to the host migration paths automatically, ' \
           'so you only need to run `rails db:migrate` afterwards.'

      def copy_initializer
        template 'devhago_health_check_initializer.rb', 'config/initializers/devhago_health_check.rb'
      end

      def show_post_install_message
        say <<~MSG
          DevhagoHealthCheck installed.

          Next steps:
            1. Mount the engine in config/routes.rb:
                 mount DevhagoHealthCheck::Engine => "/"
            2. Run the migration:
                 bin/rails db:migrate
            3. Hit the endpoint:
                 curl http://localhost:3000/health_check
        MSG
      end
    end
  end
end
