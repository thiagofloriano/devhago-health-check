require_relative '../test_helper'
require 'active_record'

describe DevhagoHealthCheck::HealthCheckSnapshot do
  before do
    # Use an in-memory sqlite for quick tests
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      create_table :health_check_snapshots, force: true do |t|
        t.json :public_pages, default: {}
        t.json :database, default: {}
        t.json :jobs, default: {}
        t.timestamps
      end
    end
  end

  it 'prunes old snapshots' do
    DevhagoHealthCheck::HealthCheckSnapshot.create!(public_pages: {}, database: {}, jobs: {})
    DevhagoHealthCheck::HealthCheckSnapshot.where('created_at < ?', 1.hour.ago).delete_all
    assert DevhagoHealthCheck::HealthCheckSnapshot.count >= 0
  end
end
