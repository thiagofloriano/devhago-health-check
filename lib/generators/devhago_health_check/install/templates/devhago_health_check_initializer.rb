# Devhago Health Check initializer
# Customize behavior for your host app here

DevhagoHealthCheck.configure do |config|
  # Timeout per public page in milliseconds (default: 1000)
  config.page_timeout_ms = ENV.fetch('HEALTH_CHECK_PAGE_TIMEOUT_MS', 1000).to_i

  # Cache window for snapshots (seconds). If a snapshot exists within this
  # window the endpoint will return the cached compact payload and avoid
  # re-running checks. Default: 300 (5 minutes).
  config.cache_window_seconds = ENV.fetch('HEALTH_CHECK_CACHE_WINDOW_SECONDS', 300).to_i

  # Table name for snapshots (default: health_check_snapshots)
  # If you want isolation, change to something like 'devhago_health_check_snapshots'
  config.table_name = ENV.fetch('DEVHAGO_HEALTH_CHECK_TABLE', 'health_check_snapshots')

  # public_pages can be:
  # - an Array of paths
  # - a Proc/lambda returning an Array
  # - a Symbol naming a helper method on ApplicationController
  # Uncomment and adapt for your app if you want explicit control:
  # config.public_pages = ['/','/pwa.js','/manifest.json']
  # or
  # config.public_pages = -> { ['/','/about'] }
  # or
  # config.public_pages = :health_public_pages
end
