# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [0.3.0] - 2026-05-30

### Adicionado
- Opção de configuração `check_jobs` (`:auto` / `true` / `false`) para controlar a verificação de jobs
- Opção de configuração `snapshot_retention_hours` (padrão: 168h / 7 dias) usada por `prune_old!`
- Variáveis de ambiente `HEALTH_CHECK_JOBS` e `HEALTH_CHECK_RETENTION_HOURS`
- Arquivo `LICENSE` (MIT), referenciado pela gemspec e README
- Testes para as novas opções de configuração e para `prune_old!`

### Corrigido
- **Jobs check não derruba mais apps sem Solid Queue**: no modo `:auto`, quando
  nenhum backend de jobs é detectado, a verificação é marcada como `ok` (skipped)
  em vez de retornar `503`
- **Generator `install` quebrado**: removida a cópia de migration inexistente que
  fazia `rails g devhago_health_check:install` falhar; a migration da engine já é
  anexada automaticamente aos paths do app host
- **Auto-discovery**: quando `PublicPagesController` não está definido, nenhuma rota
  é descoberta (antes, todas as rotas GET eram incluídas por engano)
- `prune_old!` agora respeita `snapshot_retention_hours` (antes fixo em 24h, em
  desacordo com a documentação que dizia 7 dias)
- Comparação de Bearer token agora é constant-time (`ActiveSupport::SecurityUtils.secure_compare`)
- Engine: `start_with?` em vez de `match` ao comparar paths de migration
- Payload sem cache agora inclui `from_cache: false` (consistente com o README)

### Alterado
- Verificações de banco e jobs extraídas para métodos privados no controller,
  removendo duplicação de medição de tempo e tratamento de erros
- Metadados da gemspec apontam para o repositório correto

## [0.2.0] - 2026-02-22

### Adicionado
- Suporte completo a Docker e produção com Kamal
- Variável de ambiente `DOCKER_BUILD` para detectar builds de produção
- Autenticação via Bearer Token opcional
- Requisições HTTP reais via `Net::HTTP` ao invés de `Rack::MockRequest`
- Auto-discovery inteligente de rotas públicas
- Documentação completa no README.md
- Arquivo EXAMPLES.md com exemplos práticos
- Suporte a cache bypass via parâmetro `?bypass_cache=true`

### Alterado
- **BREAKING:** Mudança de `Rack::MockRequest` para `Net::HTTP`
  - Agora testa o stack completo (proxy, SSL, DNS)
  - Requisições passam pelo servidor web real
  - Headers corretos por tipo de arquivo (.js, .json)
- Migração atualizada: campo `solid_queue` renomeado para `jobs`
- Gemspec corrigido: `require_paths` e `File.expand_path` ajustados
- Engine configurado com `autoload_paths` e `eager_load_paths`

### Corrigido
- Path gems funcionando corretamente em Docker builds
- Gemfile.lock sendo corrigido automaticamente no Dockerfile
- Suporte a rotas PWA sem conflitos com asset pipeline
- Erro de sintaxe em initializer exemplo

### Documentação
- README.md completamente reescrito com exemplos
- EXAMPLES.md criado com casos de uso práticos
- Seção de troubleshooting expandida
- Exemplos de integração com Kubernetes, AWS ALB, UptimeRobot

## [0.1.0] - 2026-02-20

### Adicionado
- Versão inicial da gem
- Health check de páginas públicas via Rack::MockRequest
- Health check de banco de dados
- Health check de jobs (Solid Queue)
- Sistema de snapshots com cache
- Configuração via initializer
- Rake task para poda de snapshots antigos
- Migration para tabela `health_check_snapshots`

### Características Iniciais
- Suporte a timeout configurável por página
- Cache com janela configurável
- Descoberta automática de rotas públicas
- Persistência em JSONB
- Resposta JSON compacta
