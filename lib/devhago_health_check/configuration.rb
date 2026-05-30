module DevhagoHealthCheck
  class Configuration
    attr_accessor :page_timeout_ms,
                  :cache_window_seconds,
                  :table_name,
                  :public_pages,
                  :bearer_token,
                  :check_jobs,
                  :snapshot_retention_hours

    def initialize
      @page_timeout_ms = ENV.fetch('HEALTH_CHECK_PAGE_TIMEOUT_MS', '1000').to_i
      @cache_window_seconds = ENV.fetch('HEALTH_CHECK_CACHE_WINDOW_SECONDS', '300').to_i
      @table_name = ENV.fetch('DEVHAGO_HEALTH_CHECK_TABLE', 'health_check_snapshots')
      @public_pages = nil
      @bearer_token = ENV.fetch('HEALTH_CHECK_BEARER_TOKEN', nil)
      # :auto  -> check Solid Queue when present, skip gracefully otherwise
      # true   -> always require a job backend (fail if missing)
      # false  -> never check jobs (always reported as ok/skipped)
      @check_jobs = parse_check_jobs(ENV['HEALTH_CHECK_JOBS'])
      # Retention window for persisted snapshots, in hours (default: 7 days).
      @snapshot_retention_hours = ENV.fetch('HEALTH_CHECK_RETENTION_HOURS', '168').to_i
    end

    # Duplicates the configuration for testing purposes
    def dup
      duped = self.class.new
      duped.page_timeout_ms = @page_timeout_ms
      duped.cache_window_seconds = @cache_window_seconds
      duped.table_name = @table_name
      duped.public_pages = @public_pages
      duped.bearer_token = @bearer_token
      duped.check_jobs = @check_jobs
      duped.snapshot_retention_hours = @snapshot_retention_hours
      duped
    end

    private

    def parse_check_jobs(value)
      case value&.to_s&.downcase
      when 'false', '0', 'off', 'no', 'disabled' then false
      when 'true', '1', 'on', 'yes' then true
      else :auto
      end
    end
  end
end
