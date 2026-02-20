# frozen_string_literal: true

module EngineLlm
  class Engine < ::Rails::Engine
    isolate_namespace EngineLlm
    include LibraryPlatform::AppendMigrations

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
          if ENV["OLLAMA_BASE_URL"].present?
            base = ENV.fetch("OLLAMA_BASE_URL", "http://localhost:11434")
            base = "#{base}/v1" unless base.end_with?("/v1")
            config.ollama_api_base = base
          end
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

    # Seed providers and default preference on boot (idempotent).
    # Runs after migrations so the table exists; skips silently if DB is not ready.
    initializer "engine_llm.seed_providers", after: "engine_llm.configure_llm" do
      config.after_initialize do
        EngineLlm::Engine.seed_providers!
      end
    end

    class << self
      def seed_providers! # rubocop:disable Metrics/MethodLength
        return unless provider_table_ready?

        providers_data.each do |pdata|
          provider = Provider.find_or_create_by!(slug: pdata[:slug]) do |p|
            p.name     = pdata[:name]
            p.env_key  = pdata[:env_key]
            p.position = pdata[:position]
          end

          pdata[:models].each do |mdata|
            ProviderModel.find_or_create_by!(value: mdata[:value]) do |m|
              m.provider = provider
              m.label    = mdata[:label]
              m.position = mdata[:position]
              m.free     = mdata.fetch(:free, false)
            end
          end
        end

        # Default preference: first configured provider's first model
        pref = Preference.first_or_create!
        if pref.default_model.nil?
          default = ProviderModel.find_by(value: "anthropic:claude-sonnet-4-20250514")
          pref.update!(default_model: default) if default
        end

        # Backward-compat: seed cl_settings defaults
        { "model" => pref.model_value || "anthropic:claude-sonnet-4-20250514",
          "temperature" => "0.7",
          "max_tokens" => "4096" }.each do |key, value|
          Setting.find_or_create_by!(key: key) { |s| s.value = value }
        end
      rescue => e
        Rails.logger.warn("[EngineLlm] Provider seeding skipped: #{e.message}")
      end

      private

      def provider_table_ready?
        ActiveRecord::Base.connection.table_exists?("cl_providers")
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
        false
      end

      def providers_data
        [
          { name: "Z.ai",       slug: "zai",        env_key: "ZAI_API_KEY",        position: 0, models: [
            { value: "zai:glm-4.7",  label: "GLM 4.7",  position: 0 },
            { value: "zai:glm-4.6",  label: "GLM 4.6",  position: 1 },
            { value: "zai:glm-4.5",  label: "GLM 4.5",  position: 2 }
          ] },
          { name: "Anthropic",  slug: "anthropic",  env_key: "ANTHROPIC_API_KEY",  position: 1, models: [
            { value: "anthropic:claude-sonnet-4-20250514", label: "Claude Sonnet 4", position: 0 },
            { value: "anthropic:claude-haiku-4-20250414",  label: "Claude Haiku 4",  position: 1 }
          ] },
          { name: "OpenAI",     slug: "openai",     env_key: "OPENAI_API_KEY",     position: 2, models: [
            { value: "openai:gpt-4o",      label: "GPT-4o",      position: 0 },
            { value: "openai:gpt-4o-mini", label: "GPT-4o Mini", position: 1 }
          ] },
          { name: "Gemini",     slug: "gemini",     env_key: "GEMINI_API_KEY",     position: 3, models: [
            { value: "gemini:gemini-2.5-pro",   label: "Gemini 2.5 Pro",   position: 0 },
            { value: "gemini:gemini-2.5-flash", label: "Gemini 2.5 Flash", position: 1 }
          ] },
          { name: "OpenRouter", slug: "openrouter", env_key: "OPENROUTER_API_KEY", position: 4, models: [
            { value: "openrouter:anthropic/claude-sonnet-4",  label: "Claude Sonnet 4 (OpenRouter)", position: 0 },
            { value: "openrouter:google/gemini-2.5-pro",      label: "Gemini 2.5 Pro (OpenRouter)",  position: 1 },
            { value: "openrouter:moonshotai/kimi-k2",         label: "Kimi K2",                      position: 2 }
          ] },
          { name: "Ollama", slug: "ollama", env_key: "OLLAMA_BASE_URL", position: 5, models: [
            { value: "ollama:llama3",    label: "Llama 3 (8B)",    position: 0, free: true },
            { value: "ollama:mistral",   label: "Mistral (7B)",    position: 1, free: true },
            { value: "ollama:gemma2",    label: "Gemma 2 (9B)",    position: 2, free: true },
            { value: "ollama:codellama", label: "Code Llama (7B)", position: 3, free: true },
            { value: "ollama:phi3",      label: "Phi-3 (3.8B)",    position: 4, free: true },
            { value: "ollama:qwen2.5",       label: "Qwen 2.5",           position: 5, free: true },
            { value: "ollama:command-r",      label: "Command R (Cohere)",  position: 6, free: true },
            { value: "ollama:command-r-plus", label: "Command R+ (Cohere)", position: 7, free: true }
          ] }
        ]
      end
    end
  end
end
