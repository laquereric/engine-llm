# frozen_string_literal: true

module EngineLlm
  class MessagesController < ApplicationController
    before_action :find_conversation

    def create
      user_content = params[:content].to_s.strip
      if user_content.blank?
        redirect_to conversation_path(@conversation), alert: "Message cannot be blank."
        return
      end

      # Work with the persisted transcript array (AR column), not Raix's TranscriptAdapter
      messages = @conversation.read_attribute(:transcript) || []
      messages << { "role" => "user", "content" => user_content }

      # Feed messages into Raix's transcript for the LLM call
      @conversation.transcript.clear
      messages.each { |msg| @conversation.transcript << msg }

      # Ensure model is set from preferences (fall back to settings for backward compat)
      pref = Preference.instance
      @conversation.model ||= pref.model_value || Setting.get("model")

      # Call Raix chat_completion to get the assistant response
      begin
        response = @conversation.chat_completion(
          params: {
            temperature: pref.temperature&.to_f || Setting.get("temperature").to_f,
            max_tokens:  pref.max_tokens         || Setting.get("max_tokens").to_i
          }
        )

        messages << { "role" => "assistant", "content" => response }
      rescue => e
        Rails.logger.error("[LLM] chat_completion failed: #{e.class}: #{e.message}")
        messages << { "role" => "assistant", "content" => "Error: #{e.message}" }
      end

      # Update title from first user message if still default
      title_changed = false
      if @conversation.title == "New conversation"
        @conversation.title = user_content.truncate(60)
        title_changed = true
      end

      @conversation.write_attribute(:transcript, messages)
      @conversation.save!

      # Keep session state name in sync with conversation title
      if title_changed && defined?(EngineLlmState::SessionState)
        EngineLlmState::SessionState
          .for_conversation(@conversation.id)
          .update_all(name: @conversation.title)
      end

      # Ingest chat messages as bronze facts for the memory pipeline
      if defined?(LlmMemory::BronzeFact)
        [{ role: "user", content: user_content },
         { role: "assistant", content: response }].each do |msg|
          LlmMemory::BronzeFact.create!(
            source: "engine-llm:conversation:#{@conversation.id}",
            source_type: "llm_chat",
            raw_data: { role: msg[:role], content: msg[:content],
                        conversation_id: @conversation.id, model: @conversation.model },
            ingested_at: Time.current
          )
        end
      end

      redirect_to conversation_path(@conversation)
    end

    private

    def find_conversation
      @conversation = Conversation.find(params[:conversation_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to conversations_path, alert: "Conversation not found."
    end
  end
end
