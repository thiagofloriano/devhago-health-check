require_relative '../test_helper'

describe DevhagoHealthCheck::Configuration do
  before do
    @original_config = DevhagoHealthCheck.config.dup
  end

  after do
    # Restore original config after each test
    DevhagoHealthCheck.configure do |config|
      config.page_timeout_ms = @original_config.page_timeout_ms
      config.cache_window_seconds = @original_config.cache_window_seconds
      config.table_name = @original_config.table_name
      config.bearer_token = @original_config.bearer_token
      config.public_pages = @original_config.public_pages
      config.check_jobs = @original_config.check_jobs
      config.snapshot_retention_hours = @original_config.snapshot_retention_hours
    end
  end

  describe 'defaults' do
    it 'has default page_timeout_ms' do
      config = DevhagoHealthCheck::Configuration.new
      assert_equal 1000, config.page_timeout_ms
    end

    it 'has default cache_window_seconds' do
      config = DevhagoHealthCheck::Configuration.new
      assert_equal 300, config.cache_window_seconds
    end

    it 'has default table_name' do
      config = DevhagoHealthCheck::Configuration.new
      assert_equal 'health_check_snapshots', config.table_name
    end

    it 'has nil bearer_token by default' do
      config = DevhagoHealthCheck::Configuration.new
      assert_nil config.bearer_token
    end

    it 'has nil public_pages by default (auto-discovery)' do
      config = DevhagoHealthCheck::Configuration.new
      assert_nil config.public_pages
    end

    it 'defaults check_jobs to :auto' do
      config = DevhagoHealthCheck::Configuration.new
      assert_equal :auto, config.check_jobs
    end

    it 'defaults snapshot_retention_hours to 168 (7 days)' do
      config = DevhagoHealthCheck::Configuration.new
      assert_equal 168, config.snapshot_retention_hours
    end
  end

  describe 'configuration' do
    it 'allows setting page_timeout_ms' do
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 2000
      end

      assert_equal 2000, DevhagoHealthCheck.config.page_timeout_ms
    end

    it 'allows setting cache_window_seconds' do
      DevhagoHealthCheck.configure do |config|
        config.cache_window_seconds = 600
      end

      assert_equal 600, DevhagoHealthCheck.config.cache_window_seconds
    end

    it 'allows setting custom table_name' do
      DevhagoHealthCheck.configure do |config|
        config.table_name = 'custom_health_snapshots'
      end

      assert_equal 'custom_health_snapshots', DevhagoHealthCheck.config.table_name
    end

    it 'allows setting bearer_token' do
      DevhagoHealthCheck.configure do |config|
        config.bearer_token = 'secret-token-123'
      end

      assert_equal 'secret-token-123', DevhagoHealthCheck.config.bearer_token
    end

    it 'allows setting public_pages as array' do
      pages = ['/', '/about', '/pwa.js']
      DevhagoHealthCheck.configure do |config|
        config.public_pages = pages
      end

      assert_equal pages, DevhagoHealthCheck.config.public_pages
    end

    it 'allows setting public_pages as proc' do
      pages_proc = -> { ['/', '/about'] }
      DevhagoHealthCheck.configure do |config|
        config.public_pages = pages_proc
      end

      assert_equal pages_proc, DevhagoHealthCheck.config.public_pages
    end

    it 'allows setting public_pages as symbol' do
      DevhagoHealthCheck.configure do |config|
        config.public_pages = :custom_public_pages
      end

      assert_equal :custom_public_pages, DevhagoHealthCheck.config.public_pages
    end

    it 'allows disabling the jobs check' do
      DevhagoHealthCheck.configure do |config|
        config.check_jobs = false
      end

      assert_equal false, DevhagoHealthCheck.config.check_jobs
    end

    it 'allows setting snapshot_retention_hours' do
      DevhagoHealthCheck.configure do |config|
        config.snapshot_retention_hours = 48
      end

      assert_equal 48, DevhagoHealthCheck.config.snapshot_retention_hours
    end
  end

  describe 'dup' do
    it 'copies all attributes including check_jobs and retention' do
      DevhagoHealthCheck.configure do |config|
        config.check_jobs = false
        config.snapshot_retention_hours = 72
        config.bearer_token = 'abc'
      end

      duped = DevhagoHealthCheck.config.dup

      assert_equal false, duped.check_jobs
      assert_equal 72, duped.snapshot_retention_hours
      assert_equal 'abc', duped.bearer_token
    end
  end

  describe 'validation' do
    it 'accepts positive page_timeout_ms' do
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 5000
      end

      assert_equal 5000, DevhagoHealthCheck.config.page_timeout_ms
    end

    it 'accepts zero cache_window_seconds (no cache)' do
      DevhagoHealthCheck.configure do |config|
        config.cache_window_seconds = 0
      end

      assert_equal 0, DevhagoHealthCheck.config.cache_window_seconds
    end

    it 'accepts negative cache_window_seconds (disables cache)' do
      DevhagoHealthCheck.configure do |config|
        config.cache_window_seconds = -1
      end

      assert_equal(-1, DevhagoHealthCheck.config.cache_window_seconds)
    end
  end

  describe 'multiple configurations' do
    it 'maintains last configuration' do
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 1000
      end

      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 2000
      end

      assert_equal 2000, DevhagoHealthCheck.config.page_timeout_ms
    end

    it 'only updates specified values' do
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 1500
        config.bearer_token = 'token-1'
      end

      DevhagoHealthCheck.configure do |config|
        config.cache_window_seconds = 600
      end

      assert_equal 1500, DevhagoHealthCheck.config.page_timeout_ms
      assert_equal 'token-1', DevhagoHealthCheck.config.bearer_token
      assert_equal 600, DevhagoHealthCheck.config.cache_window_seconds
    end
  end

  describe 'edge cases' do
    it 'handles empty string bearer_token' do
      DevhagoHealthCheck.configure do |config|
        config.bearer_token = ''
      end

      assert_equal '', DevhagoHealthCheck.config.bearer_token
    end

    it 'handles empty array public_pages' do
      DevhagoHealthCheck.configure do |config|
        config.public_pages = []
      end

      assert_equal [], DevhagoHealthCheck.config.public_pages
    end

    it 'handles very large timeout values' do
      DevhagoHealthCheck.configure do |config|
        config.page_timeout_ms = 999_999
      end

      assert_equal 999_999, DevhagoHealthCheck.config.page_timeout_ms
    end
  end
end
