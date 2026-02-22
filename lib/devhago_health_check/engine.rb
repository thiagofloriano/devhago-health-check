require 'rails'

module DevhagoHealthCheck
  class Engine < ::Rails::Engine
    isolate_namespace DevhagoHealthCheck

    # Ensure app directories are in autoload paths
    config.autoload_paths += %W[
      #{config.root}/app/models
      #{config.root}/app/controllers
      #{config.root}/app/helpers
    ]

    # Also add to eager load paths for production
    config.eager_load_paths += %W[
      #{config.root}/app/models
      #{config.root}/app/controllers
      #{config.root}/app/helpers
    ]

    # Load the main module configuration before engine initializes
    config.before_initialize do
      require 'devhago_health_check' unless defined?(DevhagoHealthCheck.configure)
    end

    initializer 'devhago_health_check.append_migrations' do |app|
      unless app.root.to_s.match(root.to_s)
        config.paths['db/migrate'].expanded.each do |path|
          app.config.paths['db/migrate'] << path
        end
      end
    end
  end
end
