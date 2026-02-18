# frozen_string_literal: true

module EngineLlm
  class Setting < ApplicationRecord
    self.table_name = "cl_settings"

    validates :key, presence: true, uniqueness: true

    def self.get(key)
      find_by(key: key)&.value
    end

    def self.set(key, value)
      record = find_or_initialize_by(key: key)
      record.update!(value: value.to_s)
    end
  end
end
