namespace :devhago_health_check do
  desc 'Prune old health check snapshots'
  task prune: :environment do
    DevhagoHealthCheck::HealthCheckSnapshot.prune_old!
    puts 'Pruned old health check snapshots'
  end
end
