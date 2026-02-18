# frozen_string_literal: true

module EngineLlm
  class ProviderModel < ApplicationRecord
    self.table_name = "cl_provider_models"

    belongs_to :provider

    scope :ordered,   -> { order(:position) }
    scope :active,    -> { where(active: true) }
    scope :free_tier, -> { where(free: true) }

    # "openrouter" from "openrouter:moonshotai/kimi-k2:free"
    def provider_slug
      value.to_s.split(":").first
    end

    # "moonshotai/kimi-k2:free" from "openrouter:moonshotai/kimi-k2:free"
    def bare_model_name
      parts = value.to_s.split(":", 2)
      parts.size == 2 ? parts.last : parts.first
    end
  end
end
