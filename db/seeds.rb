# frozen_string_literal: true

# Idempotent seed for LLM providers, models, and preferences.

PROVIDERS = [
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
    { value: "openrouter:moonshotai/kimi-k2",    label: "Kimi K2",               position: 2 }
  ] }
].freeze

PROVIDERS.each do |pdata|
  provider = EngineLlm::Provider.find_or_create_by!(slug: pdata[:slug]) do |p|
    p.name     = pdata[:name]
    p.env_key  = pdata[:env_key]
    p.position = pdata[:position]
  end

  pdata[:models].each do |mdata|
    EngineLlm::ProviderModel.find_or_create_by!(value: mdata[:value]) do |m|
      m.provider = provider
      m.label    = mdata[:label]
      m.position = mdata[:position]
      m.free     = mdata.fetch(:free, false)
    end
  end
end

# Create singleton preference with default model = Claude Sonnet 4
default_model = EngineLlm::ProviderModel.find_by(value: "anthropic:claude-sonnet-4-20250514")
pref = EngineLlm::Preference.first_or_create!
if pref.default_model.nil? && default_model
  pref.update!(default_model: default_model)
end

# Backward-compat: also seed cl_settings defaults
{
  "model" => pref.model_value || "anthropic:claude-sonnet-4-20250514",
  "temperature" => "0.7",
  "max_tokens" => "4096"
}.each do |key, value|
  EngineLlm::Setting.find_or_create_by!(key: key) do |s|
    s.value = value
  end
end
