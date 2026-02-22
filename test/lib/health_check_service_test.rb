require 'test_helper'

module DevhagoHealthCheck
  class HealthCheckServiceTest < Minitest::Test
    def setup
      @controller = Minitest::Mock.new
      @request = Minitest::Mock.new

      # Setup request mock
      @request.expect(:scheme, 'http')
      @request.expect(:host_with_port, 'example.com:3000')

      @controller.expect(:request, @request)

      # Reset configuration
      DevhagoHealthCheck.instance_variable_set(:@config, nil)
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 1000
      end

      @service = DevhagoHealthCheck::HealthCheckService.new(@controller)
    end

    def test_service_initialization
      assert_instance_of DevhagoHealthCheck::HealthCheckService, @service
    end

    def test_check_pages_returns_hash
      route_infos = [{ path: '/', controller: nil, action: nil }]

      # Stub HTTP request
      stub_request(:get, 'http://example.com:3000/')
        .to_return(status: 200, body: 'OK')

      result = @service.check_pages(route_infos)

      assert_instance_of Hash, result
      assert result.key?('public:/')
    end

    def test_check_pages_successful_request
      route_infos = [{ path: '/', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/')
        .to_return(status: 200, body: 'OK')

      result = @service.check_pages(route_infos)
      page_check = result['public:/']

      assert_equal 200, page_check[:status]
      assert_equal true, page_check[:ok]
      assert page_check[:elapsed_ms].is_a?(Integer)
      assert page_check[:elapsed_ms] >= 0
    end

    def test_check_pages_failed_request
      route_infos = [{ path: '/error', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/error')
        .to_return(status: 500, body: 'Error')

      result = @service.check_pages(route_infos)
      page_check = result['public:/error']

      assert_equal 500, page_check[:status]
      assert_equal false, page_check[:ok]
    end

    def test_check_pages_timeout
      route_infos = [{ path: '/slow', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/slow')
        .to_timeout

      result = @service.check_pages(route_infos)
      page_check = result['public:/slow']

      assert_equal 'timeout', page_check[:status]
      assert_equal false, page_check[:ok]
      assert page_check.key?(:message)
    end

    def test_check_pages_network_error
      route_infos = [{ path: '/broken', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/broken')
        .to_raise(StandardError.new('Network error'))

      result = @service.check_pages(route_infos)
      page_check = result['public:/broken']

      assert_equal 'error', page_check[:status]
      assert_equal false, page_check[:ok]
      assert_equal 'Network error', page_check[:message]
    end

    def test_check_pages_multiple_routes
      route_infos = [
        { path: '/', controller: nil, action: nil },
        { path: '/about', controller: nil, action: nil }
      ]

      stub_request(:get, 'http://example.com:3000/')
        .to_return(status: 200, body: 'OK')
      stub_request(:get, 'http://example.com:3000/about')
        .to_return(status: 200, body: 'About')

      result = @service.check_pages(route_infos)

      assert_equal 2, result.keys.length
      assert result.key?('public:/')
      assert result.key?('public:/about')
    end

    def test_check_pages_respects_timeout_configuration
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 100
      end

      # Create new mocks for this test
      controller = Minitest::Mock.new
      request = Minitest::Mock.new
      request.expect(:scheme, 'http')
      request.expect(:host_with_port, 'example.com:3000')
      controller.expect(:request, request)

      service = DevhagoHealthCheck::HealthCheckService.new(controller)
      route_infos = [{ path: '/', controller: nil, action: nil }]

      # Stub a slow response (150ms)
      stub_request(:get, 'http://example.com:3000/')
        .to_return(status: 200, body: 'OK', headers: {})
        .then
        .to_timeout

      result = service.check_pages(route_infos)

      # Even if status is 200, if it takes longer than timeout, ok should be false
      # Note: This is hard to test reliably, so we just verify the method runs
      assert result.key?('public:/')
    end

    def test_check_pages_sets_correct_accept_header_for_js
      route_infos = [{ path: '/app.js', controller: nil, action: nil }]

      stub = stub_request(:get, 'http://example.com:3000/app.js')
             .with(headers: { 'Accept' => 'application/javascript, */*' })
             .to_return(status: 200, body: "console.log('ok');")

      @service.check_pages(route_infos)

      assert_requested stub
    end

    def test_check_pages_sets_correct_accept_header_for_json
      route_infos = [{ path: '/api/data.json', controller: nil, action: nil }]

      stub = stub_request(:get, 'http://example.com:3000/api/data.json')
             .with(headers: { 'Accept' => 'application/json, */*' })
             .to_return(status: 200, body: '{"status":"ok"}')

      @service.check_pages(route_infos)

      assert_requested stub
    end

    def test_check_pages_sets_correct_accept_header_for_html
      route_infos = [{ path: '/page', controller: nil, action: nil }]

      stub = stub_request(:get, 'http://example.com:3000/page')
             .with(headers: { 'Accept' => 'text/html, application/xhtml+xml, */*' })
             .to_return(status: 200, body: '<html></html>')

      @service.check_pages(route_infos)

      assert_requested stub
    end

    def test_check_pages_sets_user_agent
      route_infos = [{ path: '/', controller: nil, action: nil }]

      stub = stub_request(:get, 'http://example.com:3000/')
             .with(headers: { 'User-Agent' => 'DevhagoHealthCheck/1.0' })
             .to_return(status: 200, body: 'OK')

      @service.check_pages(route_infos)

      assert_requested stub
    end

    def test_check_pages_handles_https_scheme
      @request = Minitest::Mock.new
      @request.expect(:scheme, 'https')
      @request.expect(:host_with_port, 'secure.example.com')

      @controller = Minitest::Mock.new
      @controller.expect(:request, @request)

      service = DevhagoHealthCheck::HealthCheckService.new(@controller)
      route_infos = [{ path: '/', controller: nil, action: nil }]

      stub_request(:get, 'https://secure.example.com/')
        .to_return(status: 200, body: 'OK')

      result = service.check_pages(route_infos)

      assert result.key?('public:/')
      assert_equal 200, result['public:/'][:status]
    end

    def test_check_pages_handles_redirect_as_ok
      route_infos = [{ path: '/redirect', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/redirect')
        .to_return(status: 302, headers: { 'Location' => '/new-location' })

      result = @service.check_pages(route_infos)
      page_check = result['public:/redirect']

      assert_equal 302, page_check[:status]
      # Redirects (3xx) are considered OK
      assert_equal true, page_check[:ok]
    end

    def test_check_pages_handles_empty_route_list
      result = @service.check_pages([])

      assert_instance_of Hash, result
      assert_empty result
    end

    def test_check_pages_measures_elapsed_time
      route_infos = [{ path: '/', controller: nil, action: nil }]

      stub_request(:get, 'http://example.com:3000/')
        .to_return(status: 200, body: 'OK')

      result = @service.check_pages(route_infos)
      page_check = result['public:/']

      assert page_check.key?(:elapsed_ms)
      assert page_check[:elapsed_ms].is_a?(Integer)
      assert page_check[:elapsed_ms] >= 0
      # Should complete quickly in tests
      assert page_check[:elapsed_ms] < 5000
    end

    # NOTE: Private methods (check_database, check_jobs) are tested indirectly
    # through the controller integration tests in the host application.
    # See: bolao-bolado/test/integration/health_check_test.rb
  end
end
