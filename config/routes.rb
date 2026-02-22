DevhagoHealthCheck::Engine.routes.draw do
  get '/health_check', to: 'health_check#show'
end
