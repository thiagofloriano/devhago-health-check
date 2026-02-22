module DevhagoHealthCheck
  class HealthCheckService
    def initialize(controller)
      @controller = controller
      @request = controller.request
      @page_timeout_ms = DevhagoHealthCheck.config.page_timeout_ms
    end

    def check_pages(route_infos)
      checks = {}
      route_infos.each do |route_info|
        path = route_info[:path]
        route_info[:controller]
        route_info[:action]
        key = "public:#{path}"
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          host_with_port = begin
            @request.host_with_port
          rescue StandardError
            'localhost'
          end
          env = Rack::MockRequest.env_for(path, method: 'GET', 'HTTP_HOST' => host_with_port,
                                                'HTTP_ACCEPT' => 'text/html')
          status, = Rails.application.call(env)
          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
          ok = status.to_i.between?(200, 399) && elapsed_ms <= @page_timeout_ms
          checks[key] = { status: status.to_i, ok: ok, elapsed_ms: elapsed_ms }
        rescue StandardError => e
          elapsed_ms = begin
            ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
          rescue StandardError
            nil
          end
          checks[key] = { status: 'error', ok: false, message: e.message, elapsed_ms: elapsed_ms }
        end
      end
      checks
    end
  end
end
