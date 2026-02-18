# frozen_string_literal: true

module EngineLlm
  class HeartBeat < ApplicationRecord
    self.table_name = "cl_heartbeats"

    has_many :heart_beat_executions, foreign_key: :heartbeat_id,
             dependent: :destroy, inverse_of: :heart_beat

    validates :task_name, presence: true, uniqueness: true
    validates :interval_seconds, presence: true, numericality: { greater_than: 0 }

    scope :enabled, -> { where(enabled: true) }
    scope :due, -> { enabled.where("next_run_at <= ?", Time.current) }
    scope :by_priority, -> { order(priority: :desc) }

    def due?
      enabled? && next_run_at.present? && next_run_at <= Time.current
    end

    def schedule_next!
      update!(next_run_at: Time.current + interval_seconds.seconds)
    end

    def record_execution!(status:, started_at:, completed_at: nil, duration_ms: nil, error_message: nil, attempt_number: 1)
      heart_beat_executions.create!(
        status: status,
        started_at: started_at,
        completed_at: completed_at,
        duration_ms: duration_ms,
        error_message: error_message,
        attempt_number: attempt_number
      )
    end
  end
end
