require_relative 'lib/devhago_health_check/version'

Gem::Specification.new do |spec|
  spec.name        = 'devhago-health-check'
  spec.version     = DevhagoHealthCheck::VERSION
  spec.summary     = 'Comprehensive health check Rails Engine with Docker support'
  spec.description = 'A Rails Engine for health checks with database, jobs, and public pages verification. Supports Docker, bearer token auth, and smart caching.'
  spec.authors     = ['Devhago']
  spec.email       = 'devhago@example.com'
  spec.files       = Dir.chdir(File.expand_path(__dir__)) do
    Dir['lib/**/*', 'app/**/*', 'config/**/*', 'db/**/*', 'templates/**/*', 'README.md', 'CHANGELOG.md', 'EXAMPLES.md',
        'LICENSE']
  end
  spec.homepage    = 'https://github.com/thiagofloriano/devhago-health-check'
  spec.license     = 'MIT'
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'
  spec.add_dependency 'rails', '>= 6.0'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/thiagofloriano/devhago-health-check',
    'changelog_uri' => 'https://github.com/thiagofloriano/devhago-health-check/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/thiagofloriano/devhago-health-check/blob/main/README.md',
    'rubygems_mfa_required' => 'true'
  }
end
