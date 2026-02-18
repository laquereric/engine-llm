# frozen_string_literal: true

module EngineLlm
  class ConversationsController < ApplicationController
    before_action :find_conversation, only: %i[show destroy]

    def index
      @conversations = Conversation.order(updated_at: :desc)
    end

    def show
    end

    def create
      pref = Preference.instance
      @conversation = Conversation.new(
        title: "New conversation",
        model: pref.model_value || Setting.get("model"),
        transcript: []
      )

      if @conversation.save
        # Auto-create a session state for this conversation
        if defined?(EngineLlmState::SessionState)
          EngineLlmState::SessionState.create!(
            name: @conversation.title,
            conversation_id: @conversation.id,
            active: true
          )
        end
        redirect_to conversation_path(@conversation)
      else
        redirect_to conversations_path, alert: @conversation.errors.full_messages.join(", ")
      end
    end

    def destroy
      @conversation.destroy
      redirect_to conversations_path, notice: "Conversation deleted."
    end

    private

    def find_conversation
      @conversation = Conversation.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to conversations_path, alert: "Conversation not found."
    end
  end
end
