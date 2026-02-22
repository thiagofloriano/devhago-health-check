# Exemplos de Uso - DevhagoHealthCheck

## Exemplo Completo de Integração

### 1. Estrutura de Diretórios

```
seu-projeto/
├── devhago-health-check/     # Gem local
│   ├── app/
│   ├── lib/
│   └── README.md
└── bolao-bolado/              # Sua aplicação
    ├── Gemfile
    ├── Dockerfile
    ├── docker-compose.yml
    ├── config/
    │   ├── routes.rb
    │   └── initializers/
    │       └── devhago_health_check.rb
    ├── scripts/
    │   └── sync-vendor-gems.sh
    ├── vendor/
    │   └── gems/
    │       └── devhago-health-check/  # Cópia para produção
    └── .kamal/
        └── hooks/
            └── pre-build
```

### 2. Gemfile Completo

```ruby
# Gemfile
source "https://rubygems.org"

gem "rails"
gem "pg"
gem "puma"

# Health Check com suporte a Docker
# Development: usa ../devhago-health-check com volume
# Production: usa vendor/gems/devhago-health-check copiado no build
gem_path = ENV["DOCKER_BUILD"] == "1" ? "vendor/gems/devhago-health-check" : "../devhago-health-check"
gem "devhago-health-check", path: gem_path, require: "devhago_health_check"

# ... outras gems
```

### 3. docker-compose.yml

```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/rails
      - ../devhago-health-check:/devhago-health-check  # Volume para development
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp_dev
      - HEALTH_CHECK_BEARER_TOKEN=dev-token-secreto
    depends_on:
      - db
  
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp_dev
```

### 4. Dockerfile

```dockerfile
ARG RUBY_VERSION=3.4.8
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Variáveis de produção
ENV RAILS_ENV="production" \
    DOCKER_BUILD="1" \
    BUNDLE_PATH="/usr/local/bundle"

# Build stage
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev

# Copiar vendor gems ANTES do bundle install
COPY vendor ./vendor
COPY Gemfile Gemfile.lock ./

# Corrigir Gemfile.lock para usar vendor path
RUN sed -i 's|remote: \.\./devhago-health-check|remote: vendor/gems/devhago-health-check|g' Gemfile.lock

# Bundle install com frozen desabilitado (permite path changes)
RUN bundle config set --local frozen false && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

# Copiar código da aplicação
COPY . .

# Precompilar assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage
FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
```

### 5. Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "home#index"
  
  # Monte a engine
  begin
    mount DevhagoHealthCheck::Engine => "/"
  rescue NameError => e
    Rails.logger.warn("DevhagoHealthCheck not available: #{e.message}")
    
    # Fallback simples (opcional)
    get "/health_check", to: proc { 
      [200, {"Content-Type" => "application/json"}, ['{"status":"ok"}']] 
    }
  end
  
  # Suas rotas públicas
  get "/about", to: "pages#about"
  get "/pwa.js", to: "pwa#script"
  get "/manifest.json", to: "pwa#manifest"
  
  # Rotas autenticadas
  resources :users
  resources :posts
end
```

### 6. Initializer

```ruby
# config/initializers/devhago_health_check.rb
if defined?(DevhagoHealthCheck) && DevhagoHealthCheck.respond_to?(:configure)
  DevhagoHealthCheck.configure do |config|
    # Timeouts e cache
    config.page_timeout_ms = ENV.fetch("HEALTH_CHECK_PAGE_TIMEOUT_MS", 2000).to_i
    config.cache_window_seconds = ENV.fetch("HEALTH_CHECK_CACHE_WINDOW_SECONDS", 300).to_i
    
    # Tabela
    config.table_name = "health_check_snapshots"
    
    # Autenticação (recomendado em produção)
    config.bearer_token = ENV.fetch("HEALTH_CHECK_BEARER_TOKEN", nil)
    
    # Páginas específicas (opcional)
    # Se não configurar, usa auto-discovery
    config.public_pages = [
      "/",
      "/about",
      "/pwa.js",
      "/manifest.json"
    ]
  end
else
  Rails.logger.warn "DevhagoHealthCheck gem not loaded; skipping configuration"
end
```

### 7. Script de Sync

```bash
#!/bin/bash
# scripts/sync-vendor-gems.sh
set -e

echo "📦 Syncing devhago-health-check to vendor/gems..."

# Criar diretório se não existe
mkdir -p vendor/gems

# Remover versão antiga
rm -rf vendor/gems/devhago-health-check

# Copiar gem atualizada
if [ -d "../devhago-health-check" ]; then
  cp -r ../devhago-health-check vendor/gems/
  
  # Remover arquivos desnecessários
  rm -rf vendor/gems/devhago-health-check/.git
  rm -rf vendor/gems/devhago-health-check/.github
  rm -rf vendor/gems/devhago-health-check/tmp
  
  echo "✅ Synced successfully"
else
  echo "❌ Error: ../devhago-health-check not found"
  echo "   Make sure the gem is cloned at ../devhago-health-check"
  exit 1
fi

echo "✨ Vendor gems sync complete!"
```

### 8. Kamal Hook

```bash
#!/bin/sh
# .kamal/hooks/pre-build
set -e

echo "🔄 [pre-build] Syncing vendor gems for production build..."

# Navegue para o diretório raiz do projeto
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT="$SCRIPT_DIR/../.."
cd "$REPO_ROOT"

# Execute o script de sync
if [ -x "./scripts/sync-vendor-gems.sh" ]; then
  ./scripts/sync-vendor-gems.sh
else
  echo "⚠️  Warning: scripts/sync-vendor-gems.sh not found or not executable"
  echo "   Run: chmod +x scripts/sync-vendor-gems.sh"
  exit 1
fi

echo "✅ [pre-build] Vendor gems synced successfully"
exit 0
```

## Exemplos de Uso da API

### Teste Básico

```bash
# Health check simples
curl http://localhost:3000/health_check

# Resposta
{
  "pages": "ok",
  "db": "ok",
  "jobs": "ok",
  "ts": "2026-02-22T23:00:00Z",
  "from_cache": false
}
```

### Com Autenticação

```bash
# Com bearer token
curl -H "Authorization: Bearer seu-token-secreto" \
  http://localhost:3000/health_check

# Sem token (retorna 401)
curl -i http://localhost:3000/health_check
# HTTP/1.1 401 Unauthorized
```

### Bypass de Cache

```bash
# Forçar novo snapshot (ignora cache)
curl http://localhost:3000/health_check?bypass_cache=true

# Resposta sempre com from_cache: false
{
  "pages": "ok",
  "db": "ok",
  "jobs": "ok",
  "ts": "2026-02-22T23:01:00Z",
  "from_cache": false
}
```

### Verificar Detalhes do Snapshot

```bash
# No console Rails
bin/rails console

# Ver último snapshot
snapshot = DevhagoHealthCheck::HealthCheckSnapshot.last

# Ver páginas testadas
snapshot.public_pages
# => {
#   "public:/"=>{"ok"=>true, "status"=>200, "elapsed_ms"=>157},
#   "public:/about"=>{"ok"=>true, "status"=>200, "elapsed_ms"=>25}
# }

# Ver status do banco
snapshot.database
# => {"ok"=>true}

# Ver status de jobs
snapshot.jobs
# => {"ok"=>true}
```

## Cenários Comuns

### 1. Monitoramento Externo (UptimeRobot)

```
URL: https://seusite.com/health_check
Method: GET
Headers: Authorization: Bearer seu-token-prod
Interval: 5 minutes
Expected: HTTP 200 + contains "ok"
```

### 2. Kubernetes Liveness Probe

```yaml
livenessProbe:
  httpGet:
    path: /health_check
    port: 3000
    httpHeaders:
    - name: Authorization
      value: "Bearer seu-token"
  initialDelaySeconds: 30
  periodSeconds: 10
```

### 3. Load Balancer Health Check (AWS ALB)

```
Health Check Path: /health_check
Success Codes: 200
Interval: 30 seconds
Timeout: 5 seconds
Healthy Threshold: 2
Unhealthy Threshold: 3
```

### 4. Cron Job de Limpeza

```ruby
# config/initializers/solid_queue.rb
# ou use whenever, sidekiq-cron, etc.

# Todo domingo às 3am, limpar snapshots antigos
SolidQueue::RecurringTask.configure do |config|
  config.recurring_tasks = [
    {
      task: "devhago_health_check:prune",
      schedule: "0 3 * * 0"
    }
  ]
end
```

## Debugging

### Ver Logs do Health Check

```bash
# Development
docker compose logs -f app | grep -i health

# Production (Kamal)
kamal app logs --grep health
```

### Testar Páginas Individualmente

```bash
# Teste manual de cada página
curl -i http://localhost:3000/
curl -i http://localhost:3000/about
curl -i http://localhost:3000/pwa.js

# Verifique:
# - Status 200
# - Content-Type correto
# - Sem erros de template
```

### Verificar Rotas Descobertas

```bash
bin/rails console

# Ver quais rotas serão testadas
service = DevhagoHealthCheck::HealthCheckService.new(ApplicationController.new)
routes = service.discover_public_routes
routes.map { |r| r[:path] }
```

## Troubleshooting Comum

### Problema: Gem não encontrada no bundle install

```bash
# Verifique se a gem existe
ls -la ../devhago-health-check

# Verifique se o volume está montado (Docker)
docker compose exec app ls -la /devhago-health-check

# Force rebuild
docker compose build --no-cache app
```

### Problema: 404 nas rotas /assets/*

```ruby
# ❌ Não funciona (Propshaft intercepta)
config.public_pages = ['/assets/pwa.js']

# ✅ Funciona
config.public_pages = ['/pwa.js']
```

### Problema: Health check muito lento

```ruby
# Reduza timeout
config.page_timeout_ms = 500

# Reduza número de páginas
config.public_pages = ['/', '/about']

# Aumente cache
config.cache_window_seconds = 600  # 10 minutos
```

### Problema: Bearer token não funciona

```bash
# Verifique se o token está configurado
docker compose exec app bin/rails runner "puts DevhagoHealthCheck.config.bearer_token"

# Teste com curl verbose
curl -v -H "Authorization: Bearer seu-token" \
  http://localhost:3000/health_check

# Verifique se o header está sendo enviado corretamente
```
