require 'minitest/autorun'
require 'minitest/spec'
require 'ostruct'
require 'active_record'
require 'action_controller'
require 'rack/test'
require 'webmock/minitest'

# Load the gem
require_relative '../lib/devhago_health_check'
require_relative '../lib/devhago_health_check/engine'

# Load app files (controllers and models)
Dir[File.expand_path('../app/**/*.rb', __dir__)].each { |f| require f }

# Setup in-memory SQLite for tests
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create test schema
ActiveRecord::Schema.define do
  create_table :health_check_snapshots, force: true do |t|
    t.json :public_pages, default: {}
    t.json :database, default: {}
    t.json :jobs, default: {}
    t.timestamps
  end
end

# Mock Rails application
module Rails
  def self.application
    @application ||= Application.new
  end

  def self.logger
    @logger ||= Logger.new($stdout, level: Logger::WARN)
  end

  def self.env
    ActiveSupport::StringInquirer.new('test')
  end

  class Application
    def routes
      @routes ||= Routes.new
    end
  end

  class Routes
    def routes
      @routes ||= []
    end

    def url_helpers
      Module.new
    end
  end
end

# Configure the gem for tests
DevhagoHealthCheck.configure do |config|
  config.page_timeout_ms = 1000
  config.cache_window_seconds = 300
  config.table_name = 'health_check_snapshots'
  config.bearer_token = nil
end

# Mock controller for tests
class TestController < ActionController::Base
  def request
    @request ||= ActionDispatch::Request.new(
      'rack.input' => StringIO.new,
      'REQUEST_METHOD' => 'GET',
      'rack.url_scheme' => 'http',
      'HTTP_HOST' => 'test.example.com',
      'PATH_INFO' => '/health_check'
    )
  end

  def response
    @response ||= ActionDispatch::Response.new
  end
end

# Helper to create mock routes
def mock_route(path, controller, action, verb = 'GET', constraints = {})
  OpenStruct.new(
    path: OpenStruct.new(spec: path),
    verb: verb,
    defaults: { controller: controller, action: action },
    constraints: constraints
  )
end
