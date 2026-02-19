# frozen_string_literal: true

module EngineLlm
  class HeartBeatExecution < ApplicationRecord
    include LibraryHeartbeat::HeartBeatExecutionConcern

    self.table_name = "cl_heartbeat_executions"
  end
end
