# frozen_string_literal: true

module EngineLlm
  class TabRegistry
    Tab = Struct.new(:id, :label, :path, :engine, :position, keyword_init: true)

    def initialize
      @tabs = {}
      @mutex = Mutex.new
    end

    def register(id:, label:, path:, engine: nil, position: nil)
      @mutex.synchronize do
        pos = position || next_position
        @tabs[id.to_s] = Tab.new(id: id.to_s, label: label, path: path, engine: engine, position: pos)
      end
    end

    def all
      @tabs.values.sort_by(&:position)
    end

    def size
      @tabs.size
    end

    private

    def next_position
      return 0 if @tabs.empty?

      @tabs.values.map(&:position).max + 1
    end
  end
end
