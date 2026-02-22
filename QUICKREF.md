# Quick Reference - DevhagoHealthCheck

## Installation (1 minute)

```ruby
# Gemfile
gem_path = ENV["DOCKER_BUILD"] == "1" ? "vendor/gems/devhago-health-check" : "../devhago-health-check"
gem "devhago-health-check", path: gem_path, require: "devhago_health_check"
```

```bash
bundle install
bin/rails db:migrate
```

```ruby
# config/routes.rb
mount DevhagoHealthCheck::Engine => "/"
```

## Basic Configuration

```ruby
# config/initializers/devhago_health_check.rb
DevhagoHealthCheck.configure do |config|
  config.page_timeout_ms = 1000
  config.cache_window_seconds = 300
  config.bearer_token = ENV["HEALTH_CHECK_BEARER_TOKEN"]
end
```

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health_check` | GET | Optional | Main health check endpoint |
| `/health_check?bypass_cache=true` | GET | Optional | Force new snapshot |

## Response Format

```json
{
  "pages": "ok",
  "db": "ok",
  "jobs": "ok",
  "ts": "2026-02-22T23:00:00Z",
  "from_cache": true
}
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `page_timeout_ms` | Integer | 1000 | Timeout per page in milliseconds |
| `cache_window_seconds` | Integer | 300 | Cache duration in seconds |
| `table_name` | String | "health_check_snapshots" | Database table name |
| `bearer_token` | String | nil | Bearer token for authentication |
| `public_pages` | Array | auto-discovery | Pages to check |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DOCKER_BUILD` | Set to "1" in Dockerfile | `DOCKER_BUILD=1` |
| `HEALTH_CHECK_BEARER_TOKEN` | Bearer token for auth | `HEALTH_CHECK_BEARER_TOKEN=secret` |
| `HEALTH_CHECK_PAGE_TIMEOUT_MS` | Timeout per page | `HEALTH_CHECK_PAGE_TIMEOUT_MS=2000` |
| `HEALTH_CHECK_CACHE_WINDOW_SECONDS` | Cache duration | `HEALTH_CHECK_CACHE_WINDOW_SECONDS=600` |

## Docker Setup

### docker-compose.yml
```yaml
services:
  app:
    volumes:
      - ../devhago-health-check:/devhago-health-check
```

### Dockerfile
```dockerfile
ENV DOCKER_BUILD="1"

COPY vendor ./vendor
COPY Gemfile Gemfile.lock ./

RUN sed -i 's|remote: \.\./devhago-health-check|remote: vendor/gems/devhago-health-check|g' Gemfile.lock && \
    bundle config set --local frozen false && \
    bundle install
```

### Sync Script
```bash
#!/bin/bash
# scripts/sync-vendor-gems.sh
rm -rf vendor/gems/devhago-health-check
cp -r ../devhago-health-check vendor/gems/
rm -rf vendor/gems/devhago-health-check/.git
```

## Common Commands

```bash
# Run migration
bin/rails db:migrate

# Test endpoint
curl http://localhost:3000/health_check | jq .

# With authentication
curl -H "Authorization: Bearer token" http://localhost:3000/health_check

# Bypass cache
curl http://localhost:3000/health_check?bypass_cache=true

# Prune old snapshots
bin/rails devhago_health_check:prune

# Check gem version
bin/rails runner "puts DevhagoHealthCheck::VERSION"

# Sync to vendor
./scripts/sync-vendor-gems.sh

# Build Docker image
docker build -t myapp .

# View last snapshot
bin/rails runner "puts DevhagoHealthCheck::HealthCheckSnapshot.last.inspect"
```

## Production Checklist

- [ ] Gem synced to `vendor/gems/` via `scripts/sync-vendor-gems.sh`
- [ ] Dockerfile has `ENV DOCKER_BUILD="1"`
- [ ] Dockerfile uses `sed` to fix Gemfile.lock path
- [ ] Kamal hook `.kamal/hooks/pre-build` configured
- [ ] Bearer token configured via ENV variable
- [ ] Health check endpoint accessible from load balancer
- [ ] Monitoring service configured (UptimeRobot, Datadog, etc.)
- [ ] Snapshot pruning scheduled (cron or recurring job)

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Gem not found | Check `ls -la ../devhago-health-check` |
| Path error in Docker | Add `ENV DOCKER_BUILD="1"` to Dockerfile |
| 404 on /assets/* | Use `/pwa.js` instead of `/assets/pwa.js` |
| Slow health check | Reduce `page_timeout_ms` or `public_pages` count |
| 401 Unauthorized | Check `bearer_token` config and request header |
| Stale cache | Use `?bypass_cache=true` parameter |

## Architecture

```
Health Check Request
        ↓
Controller (auth check)
        ↓
Check for recent snapshot (cache)
        ↓
If cache miss → HealthCheckService
        ↓
    ┌───┴───┐
    ↓       ↓
Pages Check  DB Check  Jobs Check
(HTTP real) (SELECT 1) (count)
    ↓       ↓       ↓
  Store snapshot in DB
        ↓
  Return JSON response
```

## Support

- 📖 Full docs: [README.md](README.md)
- 💡 Examples: [EXAMPLES.md](EXAMPLES.md)
- 📝 Changelog: [CHANGELOG.md](CHANGELOG.md)
- 🐛 Issues: Open an issue on GitHub
