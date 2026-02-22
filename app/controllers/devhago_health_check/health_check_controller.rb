module DevhagoHealthCheck
  class HealthCheckController < ActionController::Base
    # Minimal engine controller; host app can override behavior or mount under a namespace
    def show
      # Placeholder — full implementation will be copied from host app when extracting
      render body: ({ pages: 'ok', db: 'ok', jobs: 'ok', ts: Time.now.utc.iso8601 }.to_json),
             content_type: 'application/json; charset=utf-8', status: :ok
    end
  end
end
