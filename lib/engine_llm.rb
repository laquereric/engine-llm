# frozen_string_literal: true

require "raix"
require "engine_llm/version"
require "engine_llm/tab_registry"
require "engine_llm/engine"

module EngineLlm
  class << self
    def tab_registry
      @tab_registry ||= TabRegistry.new
    end
  end
end
