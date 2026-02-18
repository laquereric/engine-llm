# frozen_string_literal: true

module EngineLlm
  class HeartBeatExecution < ApplicationRecord
    self.table_name = "cl_heartbeat_executions"

    belongs_to :heart_beat, foreign_key: :heartbeat_id, inverse_of: :heart_beat_executions

    STATUSES = %w[started completed failed retried].freeze

    validates :status, presence: true, inclusion: { in: STATUSES }
    validates :started_at, presence: true
    validates :attempt_number, presence: true, numericality: { greater_than: 0 }

    scope :recent, -> { order(started_at: :desc) }
    scope :failed, -> { where(status: "failed") }
    scope :completed, -> { where(status: "completed") }
  end
end
