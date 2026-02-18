# frozen_string_literal: true

module EngineLlm
  class Preference < ApplicationRecord
    self.table_name = "cl_preferences"

    belongs_to :default_model,     class_name: "EngineLlm::ProviderModel", optional: true
    belongs_to :preferred_provider, class_name: "EngineLlm::Provider",      optional: true

    # Singleton — only one row in this table
    def self.instance
      first_or_create!
    end

    def model_value
      default_model&.value
    end

    def provider_slug
      preferred_provider&.slug
    end
  end
end
