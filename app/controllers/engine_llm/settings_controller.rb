# frozen_string_literal: true

module EngineLlm
  class SettingsController < ApplicationController
    def show
      pref = Preference.instance
      @model       = pref.model_value || Setting.get("model")
      @temperature = Setting.get("temperature")
      @max_tokens  = Setting.get("max_tokens")

      @model_groups = Provider.model_groups
      @api_keys     = Provider.active.ordered.map { |p| [p.env_key, p.configured?] }.to_h
    end

    def update
      Setting.set("model", params[:model]) if params[:model].present?
      Setting.set("temperature", params[:temperature]) if params[:temperature].present?
      Setting.set("max_tokens", params[:max_tokens]) if params[:max_tokens].present?

      # Mirror to preferences
      if params[:model].present?
        pref = Preference.instance
        pm = ProviderModel.find_by(value: params[:model])
        pref.update!(default_model: pm) if pm
      end

      redirect_to settings_path, notice: "Settings updated."
    end
  end
end
