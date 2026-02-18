# frozen_string_literal: true

class CreateClHeartbeats < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_heartbeats do |t|
      t.string :task_name, null: false
      t.text :description
      t.integer :interval_seconds, null: false
      t.string :cron_expression
      t.datetime :last_run_at
      t.datetime :next_run_at
      t.boolean :enabled, null: false, default: true
      t.integer :priority, null: false, default: 0
      t.integer :max_retries, null: false, default: 3
      t.integer :retry_delay_seconds, null: false, default: 60
      t.json :metadata

      t.timestamps
    end

    add_index :cl_heartbeats, :task_name, unique: true
    add_index :cl_heartbeats, :next_run_at
  end
end
