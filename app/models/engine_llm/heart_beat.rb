# frozen_string_literal: true

module EngineLlm
  class HeartBeat < ApplicationRecord
    include LibraryHeartbeat::HeartBeatConcern

    self.table_name = "cl_heartbeats"
  end
end
