require_relative 'devhago_health_check/version'
require_relative 'devhago_health_check/configuration'
require_relative 'devhago_health_check/engine'

module DevhagoHealthCheck
  class << self
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    # Configuration DSL: DevhagoHealthCheck.configure do |config|; config.public_pages = ...; end
    def configure
      yield(config) if block_given?
    end
  end
end

require_relative 'devhago_health_check/health_check_service'
