# frozen_string_literal: true

module EngineLlm
  class HeartBeatExecution < ApplicationRecord
    include Heartbeat::HeartBeatExecutionConcern

    self.table_name = "cl_heartbeat_executions"
  end
end
