# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

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
