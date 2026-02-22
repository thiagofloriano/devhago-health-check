module DevhagoHealthCheck
  class Configuration
    attr_accessor :page_timeout_ms,
                  :cache_window_seconds,
                  :table_name,
                  :public_pages,
                  :bearer_token

    def initialize
      @page_timeout_ms = ENV.fetch('HEALTH_CHECK_PAGE_TIMEOUT_MS', '1000').to_i
      @cache_window_seconds = ENV.fetch('HEALTH_CHECK_CACHE_WINDOW_SECONDS', '300').to_i
      @table_name = ENV.fetch('DEVHAGO_HEALTH_CHECK_TABLE', 'health_check_snapshots')
      @public_pages = nil
      @bearer_token = ENV.fetch('HEALTH_CHECK_BEARER_TOKEN', nil)
    end

    # Duplicates the configuration for testing purposes
    def dup
      duped = self.class.new
      duped.page_timeout_ms = @page_timeout_ms
      duped.cache_window_seconds = @cache_window_seconds
      duped.table_name = @table_name
      duped.public_pages = @public_pages
      duped.bearer_token = @bearer_token
      duped
    end
  end
end
