# DevhagoHealthCheck - Documentation Index

Welcome to the DevhagoHealthCheck gem documentation!

## 📚 Documentation Files

### Getting Started
- **[README.md](README.md)** - Complete guide with installation, configuration, and usage
  - Installation (development & production)
  - Configuration options
  - How it works (HTTP real requests, cache, etc.)
  - Troubleshooting

### Quick Access
- **[QUICKREF.md](QUICKREF.md)** - Quick reference with commands and configurations
  - One-minute installation
  - API endpoints table
  - Configuration options table
  - Common commands cheatsheet
  - Production checklist
  - Troubleshooting quick fixes

### Practical Examples
- **[EXAMPLES.md](EXAMPLES.md)** - Complete integration examples
  - Full project structure
  - Docker Compose setup
  - Dockerfile configuration
  - Kamal integration
  - Kubernetes/AWS ALB examples
  - API usage examples
  - Debugging tips

### Version History
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
  - Version 0.2.0 (current) - Docker support, bearer auth, HTTP real requests
  - Version 0.1.0 - Initial release

### Templates
- **[templates/devhago_health_check.rb](templates/devhago_health_check.rb)** - Initializer template
  - Copy to `config/initializers/devhago_health_check.rb`
  - Fully commented with all options
  - Examples of different configurations

## 🚀 Quick Start (30 seconds)

1. **Add to Gemfile:**
   ```ruby
   gem_path = ENV["DOCKER_BUILD"] == "1" ? "vendor/gems/devhago-health-check" : "../devhago-health-check"
   gem "devhago-health-check", path: gem_path, require: "devhago_health_check"
   ```

2. **Install and migrate:**
   ```bash
   bundle install
   bin/rails db:migrate
   ```

3. **Mount engine in routes:**
   ```ruby
   mount DevhagoHealthCheck::Engine => "/"
   ```

4. **Test:**
   ```bash
   curl http://localhost:3000/health_check
   ```

## 📖 What to Read?

### I want to...

- **Start from scratch** → Read [README.md](README.md)
- **See working examples** → Read [EXAMPLES.md](EXAMPLES.md)
- **Quick command reference** → Read [QUICKREF.md](QUICKREF.md)
- **Setup initializer** → Copy [templates/devhago_health_check.rb](templates/devhago_health_check.rb)
- **Know what changed** → Read [CHANGELOG.md](CHANGELOG.md)
- **Deploy to production** → Read "Production" section in [README.md](README.md) and [EXAMPLES.md](EXAMPLES.md)
- **Integrate with Docker** → Read "Docker Setup" in [QUICKREF.md](QUICKREF.md)
- **Setup monitoring** → Read "Monitoring" in [EXAMPLES.md](EXAMPLES.md)
- **Troubleshoot issues** → Read "Troubleshooting" in [README.md](README.md) or [QUICKREF.md](QUICKREF.md)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Health Check Request                      │
│                 GET /health_check                            │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
         ┌────────────────────────────┐
         │  HealthCheckController     │
         │  - Bearer auth (optional)  │
         └────────────┬───────────────┘
                      ↓
         ┌────────────────────────────┐
         │  Check Recent Snapshot     │
         │  (cache_window_seconds)    │
         └────────────┬───────────────┘
                      ↓
              Cache Hit? ───Yes───> Return cached JSON
                      │
                      No
                      ↓
         ┌────────────────────────────┐
         │   HealthCheckService       │
         └────────────┬───────────────┘
                      ↓
      ┌───────────────┼───────────────┐
      ↓               ↓               ↓
┌──────────┐    ┌──────────┐   ┌──────────┐
│  Pages   │    │ Database │   │   Jobs   │
│ (HTTP)   │    │(SELECT 1)│   │ (count)  │
└──────────┘    └──────────┘   └──────────┘
      ↓               ↓               ↓
      └───────────────┼───────────────┘
                      ↓
         ┌────────────────────────────┐
         │  Store Snapshot in DB      │
         │  (HealthCheckSnapshot)     │
         └────────────┬───────────────┘
                      ↓
         ┌────────────────────────────┐
         │   Return JSON Response     │
         │   { pages, db, jobs, ts }  │
         └────────────────────────────┘
```

## 🔑 Key Features

- ✅ **Real HTTP Requests** - Tests full stack (proxy, SSL, DNS)
- ✅ **Smart Caching** - Avoids overload with configurable cache
- ✅ **Bearer Auth** - Optional token authentication
- ✅ **Auto-Discovery** - Automatically finds public routes
- ✅ **Docker Ready** - Full support for development and production
- ✅ **Database Check** - Verifies connectivity and queries
- ✅ **Jobs Check** - Monitors background job system
- ✅ **Timeout Control** - Configurable per-page timeouts
- ✅ **Snapshot History** - Persists results in database

## 📞 Support

- 🐛 **Bug reports:** Open an issue on GitHub
- 💡 **Feature requests:** Open an issue with [Feature] tag
- 📖 **Documentation issues:** Open an issue with [Docs] tag
- 🤝 **Contributing:** See contributing guidelines (coming soon)

## 📄 License

MIT License - See LICENSE file for details

---

**Version:** 0.2.0  
**Last Updated:** 2026-02-22  
**Maintained by:** Devhago
