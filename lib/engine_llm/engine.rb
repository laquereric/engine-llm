# frozen_string_literal: true

module EngineLlm
  class Engine < ::Rails::Engine
    isolate_namespace EngineLlm

    initializer "engine_llm.append_migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    # Provide EngineCore module for the design system's TabNavigationComponent.
    # Only defined if not already provided by another engine (e.g. RayswarmCore).
    initializer "engine_llm.engine_core", before: "engine_llm.register_tabs" do
      unless defined?(::EngineCore)
        ::EngineCore = Module.new do
          class << self
            def registered_tabs
              EngineLlm.tab_registry.all
            end

            def register_tab(**kwargs)
              EngineLlm.tab_registry.register(**kwargs)
            end
          end
        end
      end
    end

    # Register tabs
    initializer "engine_llm.register_tabs" do
      if defined?(::EngineCore)
        EngineCore.register_tab(
          id: "chat",
          label: "Chat",
          path: "/",
          engine: "engine_llm",
          position: 0
        )
        EngineCore.register_tab(
          id: "preferences",
          label: "Preferences",
          path: "/preferences",
          engine: "engine_llm",
          position: 5
        )
      end
    end

    # Configure Raix + RubyLLM + Z.ai provider
    initializer "engine_llm.configure_llm" do
      # Register Z.ai (Zhipu AI) as a custom OpenAI-compatible provider
      if defined?(RubyLLM)
        unless RubyLLM::Configuration.method_defined?(:zai_api_key)
          RubyLLM::Configuration.class_eval { attr_accessor :zai_api_key }
        end

        unless defined?(RubyLLM::Providers::Zai)
          zai_provider = Class.new(RubyLLM::Providers::OpenAI) do
            def api_base
              "https://api.z.ai/api/paas/v4"
            end

            def headers
              { "Authorization" => "Bearer #{@config.zai_api_key}" }
            end

            class << self
              def configuration_requirements
                %i[zai_api_key]
              end
            end
          end
          RubyLLM::Providers::Zai = zai_provider
          RubyLLM::Provider.register(:zai, RubyLLM::Providers::Zai)
        end

        RubyLLM.configure do |config|
          config.openai_api_key = ENV["OPENAI_API_KEY"] if ENV["OPENAI_API_KEY"].present?
          config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"] if ENV["ANTHROPIC_API_KEY"].present?
          config.gemini_api_key = ENV["GEMINI_API_KEY"] if ENV["GEMINI_API_KEY"].present?
          config.openrouter_api_key = ENV["OPENROUTER_API_KEY"] if ENV["OPENROUTER_API_KEY"].present?
          config.zai_api_key = ENV["ZAI_API_KEY"] if ENV["ZAI_API_KEY"].present?
        end
      end

      if defined?(Raix)
        Raix.configure do |config|
          config.before_completion = ->(context) {
            Rails.logger.info("[Raix] Sending #{context.messages.size} messages to LLM")
          }
        end
      end
    end
  end
end
