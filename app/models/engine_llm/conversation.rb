# frozen_string_literal: true

module EngineLlm
  class Conversation < ApplicationRecord
    self.table_name = "cl_conversations"

    include Raix::ChatCompletion

    serialize :transcript, coder: JSON

    validates :title, presence: true

    # Use write_attribute to set the AR column directly, avoiding
    # Raix's transcript accessor which eagerly creates ruby_llm_chat.
    after_initialize do
      write_attribute(:transcript, []) if read_attribute(:transcript).nil?
    end

    # Override Raix's ruby_llm_chat to route to the correct provider
    # based on the model prefix instead of defaulting to OpenRouter.
    def ruby_llm_chat
      @ruby_llm_chat ||= begin
        full_model = model || configuration.model
        provider = provider_from_model(full_model)
        bare_model = strip_provider_prefix(full_model)
        RubyLLM.chat(model: bare_model, provider:, assume_model_exists: true)
      end
    end

    private

    # "anthropic:claude-sonnet-4-20250514" -> :anthropic
    # Looks up provider slug from the DB first, falls back to symbol conversion.
    def provider_from_model(model_id)
      prefix = model_id.to_s.split(":").first
      if Provider.exists?(slug: prefix)
        prefix.to_sym
      else
        :anthropic
      end
    end

    # "anthropic:claude-sonnet-4-20250514" -> "claude-sonnet-4-20250514"
    # "openrouter:anthropic/claude-sonnet-4" -> "anthropic/claude-sonnet-4"
    def strip_provider_prefix(model_id)
      parts = model_id.to_s.split(":", 2)
      parts.size == 2 ? parts.last : parts.first
    end

    # Override Raix default which routes everything to OpenRouter.
    # Use the conversation's stored model (with provider prefix) rather than
    # the bare model_id that Raix passes after ruby_llm_request strips it.
    def determine_provider(_model_id, openai_override)
      return :openai if openai_override

      provider_from_model(self.model)
    end

    # Full override of Raix's ruby_llm_request to:
    # 1. Strip provider prefix from model name
    # 2. Use conversation's stored model for provider routing
    # 3. Apply max_tokens via with_params (Raix 2.0 drops it)
    def ruby_llm_request(params:, model:, messages:, openai_override: nil)
      bare_model = strip_provider_prefix(model)
      provider = determine_provider(model, openai_override)
      chat = RubyLLM.chat(model: bare_model, provider:, assume_model_exists: true)

      has_user_message = false
      messages.each do |msg|
        role = (msg[:role] || msg["role"]).to_s
        content = msg[:content] || msg["content"]
        case role
        when "system"    then chat.with_instructions(content)
        when "user"      then has_user_message = true; chat.add_message(role: :user, content:)
        when "assistant" then chat.add_message(role: :assistant, content:)
        end
      end

      chat.with_temperature(params[:temperature]) if params[:temperature]
      chat.with_params(max_tokens: params[:max_tokens].to_i) if params[:max_tokens]

      response_message = has_user_message ? chat.complete : chat.ask

      {
        "choices" => [{
          "message" => {
            "role" => "assistant",
            "content" => response_message.content,
            "tool_calls" => response_message.tool_calls
          },
          "finish_reason" => response_message.tool_call? ? "tool_calls" : "stop"
        }],
        "usage" => {
          "prompt_tokens" => response_message.input_tokens,
          "completion_tokens" => response_message.output_tokens,
          "total_tokens" => (response_message.input_tokens || 0) + (response_message.output_tokens || 0)
        }
      }
    rescue StandardError => e
      warn "RubyLLM request failed: #{e.message}"
      raise e
    end
  end
end
