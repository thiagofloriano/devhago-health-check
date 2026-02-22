# DevhagoHealthCheck

Uma Rails Engine para executar health checks completos em aplicações Rails, com suporte a Docker e deploy em produção.

## Funcionalidades

- ✅ **Verificação de páginas públicas** via HTTP real (testa proxy, SSL, DNS completos)
- ✅ **Verificação de banco de dados** (conectividade e queries)
- ✅ **Verificação de jobs** (Solid Queue ou outro backend)
- ✅ **Cache inteligente** de snapshots para evitar sobrecarga
- ✅ **Autenticação via Bearer Token** (opcional)
- ✅ **Auto-discovery de rotas** públicas
- ✅ **Suporte completo a Docker** (desenvolvimento e produção)

## Instalação

### Desenvolvimento Local

1. **Adicione a gem no Gemfile:**

```ruby
# Use DOCKER_BUILD para detectar builds de produção (setado no Dockerfile)
gem_path = ENV["DOCKER_BUILD"] == "1" ? "vendor/gems/devhago-health-check" : "../devhago-health-check"
gem "devhago-health-check", path: gem_path, require: "devhago_health_check"
```

2. **Se usar Docker Compose, adicione volume mount:**

```yaml
# docker-compose.yml
services:
  app:
    volumes:
      - ../devhago-health-check:/devhago-health-check
```

3. **Instale as dependências:**

```bash
bundle install
bin/rails db:migrate
```

### Produção (Docker/Kamal)

1. **Crie script de sync** (`scripts/sync-vendor-gems.sh`):

```bash
#!/bin/bash
set -e

echo "📦 Syncing devhago-health-check to vendor/gems..."

rm -rf vendor/gems/devhago-health-check

if [ -d "../devhago-health-check" ]; then
  cp -r ../devhago-health-check vendor/gems/
  rm -rf vendor/gems/devhago-health-check/.git
  echo "✅ Synced devhago-health-check successfully"
else
  echo "❌ Error: ../devhago-health-check not found"
  exit 1
fi
```

2. **Configure Dockerfile:**

```dockerfile
# Base stage - disponível em build e runtime
ENV RAILS_ENV="production" \
    DOCKER_BUILD="1" \
    # ... outras variáveis

# Build stage
FROM base AS build

# Install gems
COPY vendor ./vendor
COPY Gemfile Gemfile.lock ./

# Update Gemfile.lock para usar vendor path
RUN sed -i 's|remote: \.\./devhago-health-check|remote: vendor/gems/devhago-health-check|g' Gemfile.lock

RUN bundle config set --local frozen false && \
    bundle install
```

3. **Adicione hook do Kamal** (`.kamal/hooks/pre-build`):

```bash
#!/bin/sh
set -e

echo "🔄 [pre-build] Syncing vendor gems..."
./scripts/sync-vendor-gems.sh
echo "✅ [pre-build] Complete"
```

## Configuração

### Monte a Engine nas Rotas

```ruby
# config/routes.rb
begin
  mount DevhagoHealthCheck::Engine => "/"
rescue NameError => e
  Rails.logger.warn("DevhagoHealthCheck engine not available: #{e.message}")
  # Fallback opcional
  get "/health_check", to: "health_check_fallback#show"
end
```

### Configure o Initializer

```ruby
# config/initializers/devhago_health_check.rb
if defined?(DevhagoHealthCheck) && DevhagoHealthCheck.respond_to?(:configure)
  DevhagoHealthCheck.configure do |config|
    # Timeout por página em milissegundos (padrão: 1000)
    config.page_timeout_ms = ENV.fetch("HEALTH_CHECK_PAGE_TIMEOUT_MS", 1000).to_i
    
    # Janela de cache em segundos (padrão: 300)
    config.cache_window_seconds = ENV.fetch("HEALTH_CHECK_CACHE_WINDOW_SECONDS", 300).to_i
    
    # Nome da tabela (padrão: health_check_snapshots)
    config.table_name = ENV.fetch("DEVHAGO_HEALTH_CHECK_TABLE", "health_check_snapshots")
    
    # Bearer token para autenticação (opcional)
    config.bearer_token = ENV.fetch("HEALTH_CHECK_BEARER_TOKEN", nil)
    
    # Páginas públicas (opcional - usa auto-discovery se não configurado)
    # config.public_pages = ['/', '/pwa.js', '/manifest.json']
  end
else
  Rails.logger.warn "DevhagoHealthCheck gem not fully loaded yet; initializer skipped"
end
```


## Uso

### Endpoint

```
GET /health_check
```

**Resposta de sucesso:**
```json
{
  "pages": "ok",
  "db": "ok",
  "jobs": "ok",
  "ts": "2026-02-22T22:49:58Z",
  "from_cache": true
}
```

**Resposta com falha:**
```json
{
  "pages": "fail",
  "db": "ok",
  "jobs": "ok",
  "ts": "2026-02-22T22:49:58Z",
  "from_cache": false
}
```

### Autenticação (Opcional)

Se configurado `bearer_token`, envie o header:

```bash
curl -H "Authorization: Bearer seu-token-secreto" \
  http://localhost:3000/health_check
```

Sem o token correto, retorna **401 Unauthorized**.

### Cache Bypass

Para forçar um novo snapshot (ignorando cache):

```bash
curl http://localhost:3000/health_check?bypass_cache=true
```

## Configuração de Páginas Públicas

### Auto-Discovery (Padrão)

Se não configurar `public_pages`, a gem descobre automaticamente rotas públicas:

- Controllers que herdam de `PublicPagesController`
- Rotas GET sem parâmetros (`:id`, `*path`)
- Ignora rotas de assets (gerenciadas pelo Propshaft/Sprockets)

**Exemplo de rotas descobertas:**
- `/` (root)
- `/login`
- `/pwa.js`
- `/manifest.json`
- `/service-worker.js`

### Configuração Manual

```ruby
DevhagoHealthCheck.configure do |config|
  # Array estático
  config.public_pages = ['/', '/about', '/pwa.js']
  
  # Ou Proc/Lambda
  config.public_pages = -> { ['/', '/about'] }
  
  # Ou método do controller
  config.public_pages = :health_public_pages
end
```

### ⚠️ Importante sobre Rotas de Assets

**NÃO inclua rotas `/assets/*`** na lista de páginas públicas!

O Propshaft/Sprockets intercepta essas rotas antes do Rails router. Se você precisa testar scripts/manifests, use rotas fora de `/assets/`:

```ruby
# ❌ NÃO FUNCIONA (interceptado pelo Propshaft)
get "/assets/pwa.js", to: "pwa#script"

# ✅ FUNCIONA
get "/pwa.js", to: "pwa#script"
```

## Como Funciona

### 1. Verificação de Páginas

A gem faz **requisições HTTP reais** para cada página configurada:

```ruby
# lib/devhago_health_check/health_check_service.rb
url = URI.join("#{request.scheme}://#{request.host_with_port}", path)
response = Net::HTTP.get_response(url)
```

**Por que HTTP real?**
- Testa o stack completo: proxy, SSL, DNS, routing
- Detecta problemas de template (ERB errors)
- Valida headers e content-type corretos

### 2. Verificação de Banco

```ruby
ActiveRecord::Base.connection.execute("SELECT 1")
```

### 3. Verificação de Jobs

```ruby
SolidQueue::Job.count  # ou outro backend
```

### 4. Snapshot e Cache

- Persiste resultado em `health_check_snapshots` (tabela JSONB)
- Retorna snapshot recente se dentro da janela de cache
- Evita sobrecarga em health checks frequentes

## Manutenção

### Poda de Snapshots Antigos

```bash
# Remove snapshots com mais de 7 dias
bin/rails devhago_health_check:prune

# Agende via cron/Solid Queue
```

### Monitoramento

Use serviços como:
- **UptimeRobot**: Monitora `/health_check` a cada 5 minutos
- **Datadog**: Synthetic tests
- **New Relic**: Health check endpoint monitoring

## Troubleshooting

### Erro: "The path `/devhago-health-check` does not exist"

**Causa:** Gemfile.lock aponta para path errado em produção.

**Solução:** Garanta que o Dockerfile tem `ENV DOCKER_BUILD="1"` e rode `sed` para corrigir o Gemfile.lock:

```dockerfile
RUN sed -i 's|remote: \.\./devhago-health-check|remote: vendor/gems/devhago-health-check|g' Gemfile.lock
```

### Erro: "undefined method `data` for HealthCheckSnapshot"

**Causa:** Tabela tem campos separados (`public_pages`, `database`, `jobs`), não um campo único `data`.

**Solução:** Rode a migration correta que cria os campos individuais.

### Páginas retornam 404

**Causa:** Rotas `/assets/*` são interceptadas pelo asset pipeline.

**Solução:** Use rotas fora de `/assets/` (ex: `/pwa.js` ao invés de `/assets/pwa.js`).

### Health check muito lento

**Causa:** Muitas páginas sendo testadas ou timeout alto.

**Solução:**
- Reduza `page_timeout_ms` (padrão: 1000ms)
- Configure `public_pages` manualmente com menos rotas
- Aumente `cache_window_seconds` para reduzir frequência de checks

## Desenvolvimento da Gem

### Estrutura

```
devhago-health-check/
├── app/
│   ├── controllers/devhago_health_check/
│   │   └── health_check_controller.rb
│   └── models/devhago_health_check/
│       └── health_check_snapshot.rb
├── db/migrate/
│   └── *_create_health_check_snapshots.rb
├── lib/
│   ├── devhago_health_check.rb
│   ├── devhago_health_check/
│   │   ├── engine.rb
│   │   └── health_check_service.rb
│   └── tasks/
│       └── devhago_health_check_tasks.rake
└── devhago_health_check.gemspec
```

### Testes

```bash
# Na aplicação host
bin/rails test

# Teste manual
curl -s http://localhost:3000/health_check | jq .
```

## Licença

MIT License - veja arquivo LICENSE para detalhes.

## Contribuições

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/melhoria`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/melhoria`)
5. Abra um Pull Request

## Contato

Para dúvidas ou sugestões, abra uma issue no repositório.
