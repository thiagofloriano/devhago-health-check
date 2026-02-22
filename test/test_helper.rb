require 'minitest/autorun'
require 'rack'
require_relative '../lib/devhago_health_check'

# Minimal Rails-like stubs for engine loading during gem tests
module Rails
  def self.application
    OpenStruct.new(routes: OpenStruct.new(routes: []))
  end

  def self.logger
    Logger.new($stdout)
  end
end

# Basic test helper: ensure config defaults
DevhagoHealthCheck.configure do |c|
  c.page_timeout_ms = 1000
  c.cache_window_seconds = 300
end
