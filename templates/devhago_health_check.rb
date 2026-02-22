# DevhagoHealthCheck Initializer
# Copy this file to config/initializers/devhago_health_check.rb in your Rails app

if defined?(DevhagoHealthCheck) && DevhagoHealthCheck.respond_to?(:configure)
  DevhagoHealthCheck.configure do |config|
    # === Timeouts e Performance ===

    # Timeout máximo por página em milissegundos
    # Páginas que demorarem mais que isso serão marcadas como "fail"
    # Default: 1000 (1 segundo)
    config.page_timeout_ms = ENV.fetch('HEALTH_CHECK_PAGE_TIMEOUT_MS', 1000).to_i

    # Janela de cache em segundos
    # Se existir um snapshot recente (dentro desta janela), ele será reutilizado
    # Default: 300 (5 minutos)
    config.cache_window_seconds = ENV.fetch('HEALTH_CHECK_CACHE_WINDOW_SECONDS', 300).to_i

    # === Banco de Dados ===

    # Nome da tabela que armazena os snapshots
    # Default: "health_check_snapshots"
    config.table_name = ENV.fetch('DEVHAGO_HEALTH_CHECK_TABLE', 'health_check_snapshots')

    # === Autenticação ===

    # Bearer token para proteger o endpoint
    # Se configurado, requisições devem incluir: Authorization: Bearer <token>
    # Default: nil (sem autenticação)
    config.bearer_token = ENV.fetch('HEALTH_CHECK_BEARER_TOKEN', nil)

    # Exemplo usando Rails credentials:
    # config.bearer_token = Rails.application.credentials.dig(:health_check, :bearer_token)

    # === Páginas Públicas ===

    # Lista de páginas públicas para verificar
    # Se não configurado, usa auto-discovery (recomendado)
    #
    # Opção 1: Array de paths
    # config.public_pages = [
    #   "/",
    #   "/about",
    #   "/pwa.js",
    #   "/manifest.json",
    #   "/service-worker.js"
    # ]

    # Opção 2: Proc/Lambda
    # config.public_pages = -> {
    #   ["/", "/about", "/pwa.js"]
    # }

    # Opção 3: Symbol (método em ApplicationController)
    # config.public_pages = :health_public_pages
    #
    # E no ApplicationController:
    # def health_public_pages
    #   ['/', '/about', '/pwa.js']
    # end

    # IMPORTANTE: Não inclua rotas /assets/* pois elas são interceptadas
    # pelo asset pipeline (Propshaft/Sprockets) e nunca chegarão ao Rails.
    # Use rotas fora de /assets/ para scripts/manifests PWA.

    # === Auto-Discovery (Padrão) ===

    # Se public_pages não for configurado, a gem descobre automaticamente:
    # - Controllers que herdam de PublicPagesController
    # - Rotas GET sem parâmetros (:id, *path)
    # - Ignora rotas de assets
    #
    # Para ver quais rotas serão descobertas:
    # bin/rails runner "
    #   controller = ApplicationController.new
    #   service = DevhagoHealthCheck::HealthCheckService.new(controller)
    #   puts service.discover_public_routes.map { |r| r[:path] }.inspect
    # "
  end
else
  # A gem ainda não foi carregada (pode acontecer durante bundle install)
  Rails.logger.warn 'DevhagoHealthCheck gem not fully loaded yet; initializer skipped'
end
