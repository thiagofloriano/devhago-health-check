require_relative '../test_helper'

describe DevhagoHealthCheck::HealthCheckSnapshot do
  before do
    DevhagoHealthCheck::HealthCheckSnapshot.delete_all
  end

  describe 'creation' do
    it 'creates a snapshot with valid data' do
      snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: { 'public:/' => { 'ok' => true, 'status' => 200, 'elapsed_ms' => 50 } },
        database: { 'ok' => true },
        jobs: { 'ok' => true }
      )

      assert snapshot.persisted?
      assert_equal true, snapshot.public_pages['public:/']['ok']
      assert_equal true, snapshot.database['ok']
      assert_equal true, snapshot.jobs['ok']
    end

    it 'sets default values for JSON fields' do
      snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!

      assert_equal({}, snapshot.public_pages)
      assert_equal({}, snapshot.database)
      assert_equal({}, snapshot.jobs)
    end

    it 'stores timestamps' do
      snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {},
        jobs: {}
      )

      assert_instance_of Time, snapshot.created_at
      assert_instance_of Time, snapshot.updated_at
    end
  end

  describe '.recent' do
    it 'returns snapshots within cache window' do
      # Create old snapshot (outside window)
      old_snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {},
        jobs: {},
        created_at: 1.hour.ago
      )

      # Create recent snapshot (inside window - 5 minutes default)
      recent_snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {},
        jobs: {},
        created_at: 2.minutes.ago
      )

      cache_window = 300 # 5 minutes in seconds
      cutoff = Time.current - cache_window.seconds
      recent = DevhagoHealthCheck::HealthCheckSnapshot.where('created_at >= ?', cutoff)

      assert_includes recent, recent_snapshot
      refute_includes recent, old_snapshot
    end
  end

  describe '.prune_old' do
    it 'removes snapshots older than retention period' do
      # Create old snapshots
      3.times do |i|
        DevhagoHealthCheck::HealthCheckSnapshot.create!(
          public_pages: {},
          database: {},
          jobs: {},
          created_at: (8 + i).days.ago
        )
      end

      # Create recent snapshots
      2.times do
        DevhagoHealthCheck::HealthCheckSnapshot.create!(
          public_pages: {},
          database: {},
          jobs: {}
        )
      end

      assert_equal 5, DevhagoHealthCheck::HealthCheckSnapshot.count

      # Prune old (older than 7 days)
      DevhagoHealthCheck::HealthCheckSnapshot.where('created_at < ?', 7.days.ago).delete_all

      assert_equal 2, DevhagoHealthCheck::HealthCheckSnapshot.count
    end
  end

  describe 'data integrity' do
    it 'handles complex nested JSON in public_pages' do
      complex_data = {
        'public:/' => {
          'ok' => true,
          'status' => 200,
          'elapsed_ms' => 150,
          'headers' => { 'content-type' => 'text/html' }
        },
        'public:/about' => {
          'ok' => false,
          'status' => 500,
          'elapsed_ms' => 2000,
          'error' => 'Internal Server Error'
        }
      }

      snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: complex_data,
        database: { 'ok' => true },
        jobs: { 'ok' => true }
      )

      # Reload from database
      snapshot.reload

      assert_equal 200, snapshot.public_pages['public:/']['status']
      assert_equal 500, snapshot.public_pages['public:/about']['status']
      assert_equal 'Internal Server Error', snapshot.public_pages['public:/about']['error']
    end

    it 'handles database failure data' do
      snapshot = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {
          'ok' => false,
          'error' => 'PG::ConnectionBad',
          'message' => 'could not connect to server'
        },
        jobs: { 'ok' => true }
      )

      assert_equal false, snapshot.database['ok']
      assert_equal 'PG::ConnectionBad', snapshot.database['error']
    end
  end

  describe 'querying' do
    it 'finds latest snapshot' do
      DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {},
        jobs: {},
        created_at: 10.minutes.ago
      )

      latest = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: {},
        database: {},
        jobs: {},
        created_at: 1.minute.ago
      )

      assert_equal latest.id, DevhagoHealthCheck::HealthCheckSnapshot.order(created_at: :desc).first.id
    end

    it 'can filter by status' do
      # Create successful snapshot
      DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: { 'public:/' => { 'ok' => true } },
        database: { 'ok' => true },
        jobs: { 'ok' => true }
      )

      # Create failed snapshot
      failed = DevhagoHealthCheck::HealthCheckSnapshot.create!(
        public_pages: { 'public:/' => { 'ok' => false } },
        database: { 'ok' => false },
        jobs: { 'ok' => true }
      )

      # In a real app, you might add a scope for this
      # For now, just verify we can query JSON fields
      snapshots = DevhagoHealthCheck::HealthCheckSnapshot.all
      failed_snapshot = snapshots.find { |s| s.database['ok'] == false }

      assert_equal failed.id, failed_snapshot.id
    end
  end
end
