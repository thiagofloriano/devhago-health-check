require 'ostruct'
require 'devhago_health_check/engine'
require 'devhago_health_check/version'

module DevhagoHealthCheck
  class << self
    attr_accessor :config
  end

  self.config ||= OpenStruct.new(
    page_timeout_ms: ENV.fetch('HEALTH_CHECK_PAGE_TIMEOUT_MS', '1000').to_i,
    cache_window_seconds: ENV.fetch('HEALTH_CHECK_CACHE_WINDOW_SECONDS', '300').to_i,
    table_name: ENV.fetch('DEVHAGO_HEALTH_CHECK_TABLE', 'health_check_snapshots')
  )
end
