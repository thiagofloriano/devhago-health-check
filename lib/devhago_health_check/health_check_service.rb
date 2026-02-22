require 'net/http'
require 'uri'

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
        key = "public:#{path}"
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          # Build full URL using the actual request's scheme and host
          base_url = "#{@request.scheme}://#{@request.host_with_port}"
          url = URI.join(base_url, path)

          # Make real HTTP request with timeout
          timeout_seconds = (@page_timeout_ms / 1000.0).ceil
          response = Net::HTTP.start(
            url.host,
            url.port,
            use_ssl: url.scheme == 'https',
            open_timeout: timeout_seconds,
            read_timeout: timeout_seconds,
            ssl_timeout: timeout_seconds
          ) do |http|
            request = Net::HTTP::Get.new(url)

            # Set appropriate Accept header based on file extension
            request['Accept'] = if path.end_with?('.js')
                                  'application/javascript, */*'
                                elsif path.end_with?('.json')
                                  'application/json, */*'
                                else
                                  'text/html, application/xhtml+xml, */*'
                                end

            request['User-Agent'] = 'DevhagoHealthCheck/1.0'

            http.request(request)
          end

          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
          status = response.code.to_i
          ok = status.between?(200, 399) && elapsed_ms <= @page_timeout_ms

          checks[key] = { status: status, ok: ok, elapsed_ms: elapsed_ms }
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
          checks[key] = { status: 'timeout', ok: false, message: e.class.name, elapsed_ms: elapsed_ms }
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
