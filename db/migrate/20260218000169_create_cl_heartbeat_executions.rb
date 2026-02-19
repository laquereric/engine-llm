# frozen_string_literal: true

class CreateClHeartbeatExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_heartbeat_executions do |t|
      t.references :heartbeat, null: false, foreign_key: { to_table: :cl_heartbeats }
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration_ms
      t.text :error_message
      t.integer :attempt_number, null: false, default: 1

      t.timestamps
    end

    add_index :cl_heartbeat_executions, :status
  end
end
