module DevhagoHealthCheck
  class HealthCheckSnapshot < ActiveRecord::Base
    self.table_name = DevhagoHealthCheck.config.table_name

    scope :recent, -> { order(created_at: :desc) }

    def public_pages_status
      (public_pages || []).all? { |_, v| v['ok'] == true } ? 'ok' : 'fail'
    end

    def database_status
      (database || {})['ok'] == true ? 'ok' : 'fail'
    end

    def jobs_status
      (jobs || {})['ok'] == true ? 'ok' : 'fail'
    end

    def self.prune_old!(hours = 24)
      where('created_at < ?', hours.hours.ago).delete_all
    end
  end
end
