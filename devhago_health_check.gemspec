require_relative 'lib/devhago_health_check/version'

Gem::Specification.new do |s|
  s.name        = 'devhago-health-check'
  s.version     = DevhagoHealthCheck::VERSION
  s.summary     = 'Health check Rails Engine used by Devhago projects'
  s.authors     = ['Devhago']
  s.email       = 'devhago@example.com'
  s.files       = Dir.chdir(File.expand_path('..', __dir__)) do
    Dir['lib/**/*', 'app/**/*', 'config/**/*', 'db/**/*', 'templates/**/*']
  end
  s.homepage    = 'https://example.com/devhago-health-check'
  s.license     = 'MIT'
  s.add_dependency 'rails', '>= 6.0'
end
