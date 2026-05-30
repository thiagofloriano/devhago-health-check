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

  # How long persisted snapshots are kept, in hours, before `prune_old!`
  # removes them. Default: 168 (7 days).
  config.snapshot_retention_hours = ENV.fetch('HEALTH_CHECK_RETENTION_HOURS', 168).to_i

  # Background jobs check. Values:
  #   :auto  -> check Solid Queue when present, skip gracefully when no backend exists (default)
  #   true   -> always require a job backend (report fail if missing)
  #   false  -> never check jobs (always reported as ok)
  # config.check_jobs = :auto

  # Bearer token to protect the endpoint. When set, requests must send
  # `Authorization: Bearer <token>`. Default: nil (no auth).
  # config.bearer_token = ENV.fetch('HEALTH_CHECK_BEARER_TOKEN', nil)

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
