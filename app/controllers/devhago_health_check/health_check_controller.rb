module DevhagoHealthCheck
  class HealthCheckController < ActionController::Base
    # Minimal engine controller; host app can override behavior or mount under a namespace
    def show
      cache_window = DevhagoHealthCheck.config.cache_window_seconds

      recent = DevhagoHealthCheck::HealthCheckSnapshot.recent.where('created_at >= ?', cache_window.seconds.ago).first
      if recent
        pages_ok = begin
          recent.public_pages.values.all? { |c| c['ok'] == true }
        rescue StandardError
          false
        end
        db_ok = recent.database && recent.database['ok'] == true
        jobs_ok = recent.jobs && recent.jobs['ok'] == true
        payload = { pages: (pages_ok ? 'ok' : 'fail'), db: (db_ok ? 'ok' : 'fail'), jobs: (jobs_ok ? 'ok' : 'fail'),
                    ts: recent.created_at.utc.iso8601, from_cache: true }
        status = pages_ok && db_ok && jobs_ok ? :ok : :service_unavailable
        return render body: payload.to_json, content_type: 'application/json; charset=utf-8', status: status
      end

      # Use HealthCheckService for page checks
      route_infos = resolve_public_route_infos
      service = DevhagoHealthCheck::HealthCheckService.new(self)
      checks = service.check_pages(route_infos)

      # Database connectivity
      begin
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.execute('SELECT 1')
        end
        db_elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        checks['database'] = { ok: true, elapsed_ms: db_elapsed }
      rescue StandardError => e
        db_elapsed = begin
          ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        rescue StandardError
          nil
        end
        checks['database'] = { ok: false, message: e.message, elapsed_ms: db_elapsed }
        false
      end

      # Jobs check (formerly SolidQueue)
      begin
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if defined?(SolidQueue::Job)
          sample = SolidQueue::Job.where(finished_at: nil).limit(1).count
        else
          ActiveRecord::Base.connection.execute('SELECT 1 FROM solid_queue_jobs LIMIT 1')
          sample = 0
        end
        jobs_elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        checks['jobs'] = { ok: true, elapsed_ms: jobs_elapsed, sample: sample }
      rescue StandardError => e
        jobs_elapsed = begin
          ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        rescue StandardError
          nil
        end
        checks['jobs'] = { ok: false, message: e.message, elapsed_ms: jobs_elapsed }
        false
      end

      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - global_start) * 1000).round

      snapshot = nil
      begin
        snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(public_pages: extract_public_checks(checks),
                                                                   database: checks['database'], jobs: checks['jobs'])
        DevhagoHealthCheck::HealthCheckSnapshot.prune_old!
      rescue StandardError => e
        Rails.logger.error("DevhagoHealthCheck: failed to persist snapshot: #{e.message}")
      end

      if snapshot
        pages_ok = snapshot.public_pages.values.all? { |c| c['ok'] == true }
        db_ok = snapshot.database && snapshot.database['ok'] == true
        jobs_ok = snapshot.jobs && snapshot.jobs['ok'] == true
      else
        pages_ok = all_public_pages_ok?(checks)
        db_ok = checks['database'] && checks['database']['ok'] == true
        jobs_ok = checks['jobs'] && checks['jobs']['ok'] == true
      end

      payload = { pages: (pages_ok ? 'ok' : 'fail'), db: (db_ok ? 'ok' : 'fail'), jobs: (jobs_ok ? 'ok' : 'fail'),
                  ts: (snapshot ? snapshot.created_at.utc.iso8601 : Time.now.utc.iso8601) }
      status_code = pages_ok && db_ok && jobs_ok ? :ok : :service_unavailable
      render body: payload.to_json, content_type: 'application/json; charset=utf-8', status: status_code
    end

    private

    def resolve_public_pages
      cfg = DevhagoHealthCheck.config.public_pages
      return cfg if cfg.nil?

      if cfg.is_a?(Array)
        cfg
      elsif cfg.respond_to?(:call)
        cfg.call
      elsif cfg.is_a?(Symbol) && respond_to?(cfg)
        send(cfg)
      end
    end

    # Fallback discovery: inspect host app routes and select controllers that
    # inherit from PublicPagesController. Returns an array of hashes
    # [{ path: "/", controller: FooController, action: "index" }, ...]
    def resolve_public_route_infos
      pages = resolve_public_pages
      return pages.map { |p| { path: p, controller: nil, action: nil } } if pages.is_a?(Array)

      infos = []
      Rails.application.routes.routes.each do |route|
        verb = route.verb.to_s
        next unless verb.include?('GET') || verb == '' || verb =~ /GET/

        controller_name = route.defaults[:controller]
        next if controller_name.blank?

        controller_class_name = "#{controller_name.camelize}Controller"
        controller_class = begin
          controller_class_name.constantize
        rescue NameError
          nil
        end

        next unless controller_class.is_a?(Class)

        begin
          next unless controller_class < PublicPagesController
        rescue StandardError
          false
        end

        raw_path = route.path.spec.to_s
        path = raw_path.gsub(/\(.*\)$/, '')
        next if path.include?(':') || path.include?('*')

        path = '/' if path.blank?
        infos << { path: path, controller: controller_class, action: route.defaults[:action] }
      end

      deduped = {}
      infos.each do |info|
        deduped[info[:path]] ||= info
      end
      deduped.values.sort_by { |i| i[:path] }
    end

    def extract_public_checks(checks)
      checks.select { |k, _| k.to_s.start_with?('public:') }
    end

    def all_public_pages_ok?(checks)
      checks.any? && checks.select { |k, _| k.to_s.start_with?('public:') }.values.all? { |c| c['ok'] == true }
    end
  end
end
