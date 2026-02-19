# frozen_string_literal: true

module EngineLlm
  class Provider < ApplicationRecord
    self.table_name = "cl_providers"

    has_many :provider_models, dependent: :destroy

    scope :ordered, -> { order(:position) }
    scope :active,  -> { where(active: true) }

    def configured?
      if slug == "ollama"
        ENV["OLLAMA_BASE_URL"].present?
      else
        ENV[env_key].present?
      end
    end

    # Returns providers sorted: configured first, then unconfigured
    def self.configured_first
      active.ordered.sort_by { |p| p.configured? ? 0 : 1 }
    end

    # Returns the same hash shape as the old PROVIDER_MODELS constant
    # so the settings view works unchanged.
    def self.model_groups
      configured_first.map do |provider|
        {
          provider: provider.name,
          env: provider.env_key,
          models: provider.provider_models.active.ordered.map do |m|
            { value: m.value, label: m.label, free: m.free }
          end
        }
      end
    end
  end
end
