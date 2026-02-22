# devhago-health-check

Uma Rails Engine simples para executar checks de saúde (health check) em aplicações Rails.

Objetivo
- Verificar páginas públicas (renderizadas pela própria app) — com timeout configurável
- Verificar conectividade com o banco (SELECT 1)
- Verificar acesso à fila de jobs (campo `jobs` nos snapshots)
- Persistir snapshots em uma tabela JSONB e retornar um JSON compacto para monitores externos

Instalação (desenvolvimento local)

1) Adicione a gem via path no Gemfile do seu projeto host:

   gem 'devhago-health-check', path: '../devhago-health-check'

2) Instale as gems e rode migrations:

   bundle install
   # com Docker Compose
   docker compose run --rm app bin/rails db:migrate

3) Monte a engine nas suas rotas (exemplo em `config/routes.rb` do host):

   # monta em / (rota final: /health_check)
   mount DevhagoHealthCheck::Engine => '/'

   # ou monta em /internal (rota final: /internal/health_check)
   # mount DevhagoHealthCheck::Engine => '/internal'

Endpoint
- GET /health_check (ou respectivo prefixo se você montou em outro caminho)
- Resposta compacta JSON: { pages: "ok"|"fail", db: "ok"|"fail", jobs: "ok"|"fail", ts: "<ISO8601>" }
- Quando a resposta vier de snapshot em cache (janela configurável), haverá um campo adicional `from_cache: true`.

Configuração

Crie um initializer `config/initializers/devhago_health_check.rb` no seu projeto host e configure conforme necessário.

Exemplo básico (usar valores padrão):

   DevhagoHealthCheck.configure do |config|
     # timeout por página em ms (default: 1000)
     config.page_timeout_ms = 1000

     # janela de cache em segundos (default: 300)
     config.cache_window_seconds = 300

     # nome da tabela que armazena snapshots (padrão: health_check_snapshots)
     # se quiser isolamento, altere para 'devhago_health_check_snapshots'
     # mas lembre-se de ajustar migrações/nomes conforme necessário
     config.table_name = 'health_check_snapshots'

     # páginas públicas (opcional) — três formas suportadas:
     # 1) Array de paths (strings):
     #    config.public_pages = ['/','/about','/pwa.js']
     # 2) Proc/lambda que retorna um array (será executado no contexto global):
     #    config.public_pages = -> { ['/','/about'] }
     # 3) Symbol com o nome de um método que seu app expõe (recomendado para lógica dependente da app):
     #    config.public_pages = :health_public_pages
     #    # e em ApplicationController:
     #    def health_public_pages
     #      ['/', '/pwa.js']
     #    end
   end

Observações sobre public_pages
- Se não configurado, a engine faz uma descoberta automática: inspeciona
  as rotas do host app e seleciona controllers que herdem de
  `PublicPagesController`, ignorando rotas parametrizadas (com `:id` ou `*`).
- Recomendo definir explicitamente `public_pages` se sua app tiver regras específicas.

Migrações
- A engine já inclui a migration `db/migrate/*_create_health_check_snapshots.rb`.
- Após adicionar a gem, rode `bin/rails db:migrate` (ou via Docker Compose) para criar a tabela.

Rake task
- Para podas periódicas (reduzir snapshots antigos), use a task:

   bin/rails devhago_health_check:prune

Segurança
- Por padrão a engine não aplica autenticação. Em produção, proteja o endpoint com uma
  regra de rede (internal-only) ou implemente autenticação no host app (por exemplo,
  um before_action na rota que monta a engine ou via proxy reverso).

Customização / Extensão
- Você pode sobrescrever o controller da engine no host app ou criar um controller
  separado que consulte os métodos do engine se precisar de autenticação/logic custom.
- Para melhorar testabilidade, recomendo extrair a lógica em um service object
  caso queira alterar comportamento default aqui.

Publicação
- Para usar em múltiplos projetos, publique em um feed privado (git, gem server ou RubyGems).
- Para desenvolvimento local, use `gem 'devhago-health-check', path: '../devhago-health-check'`.

Exemplos rápidos

- Testar localmente:

  docker compose run --rm app bin/rails db:migrate
  curl -sS http://localhost:3000/health_check | jq .

Contribuições / testes
- A gem ainda precisa de testes automáticos (Minitest). Você pode executar a suíte do host app
  para validar a integração.

Contato
- Para dúvidas/ajustes, responda nesta conversa e eu posso gerar exemplos de código mais
  específicos para o seu projeto e ajudar a extrair o controller atual para a gem.
