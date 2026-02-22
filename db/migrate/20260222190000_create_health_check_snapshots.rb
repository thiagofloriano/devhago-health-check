class CreateHealthCheckSnapshots < ActiveRecord::Migration[6.0]
  def change
    create_table :health_check_snapshots do |t|
      t.jsonb :public_pages, default: {}
      t.jsonb :database, default: {}
      t.jsonb :jobs, default: {}
      t.timestamps
    end
    add_index :health_check_snapshots, :created_at
  end
end
