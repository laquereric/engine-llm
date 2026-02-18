# frozen_string_literal: true

module EngineLlm
  class PreferencesController < ApplicationController
    def show
      @preference = Preference.instance
      @providers  = Provider.configured_first
      @models     = ProviderModel.active.ordered.includes(:provider)
      @api_keys   = Provider.active.ordered.map { |p| [p.env_key, p.configured?] }.to_h
    end

    def update
      pref = Preference.instance

      if params[:default_model_id].present?
        pref.default_model = ProviderModel.find_by(id: params[:default_model_id])
      end

      if params[:preferred_provider_id].present?
        pref.preferred_provider = Provider.find_by(id: params[:preferred_provider_id])
      elsif params.key?(:preferred_provider_id)
        pref.preferred_provider = nil
      end

      pref.temperature = params[:temperature].to_f if params[:temperature].present?
      pref.max_tokens  = params[:max_tokens].to_i  if params[:max_tokens].present?

      pref.save!

      # Backward-compat: mirror to cl_settings
      Setting.set("model", pref.model_value) if pref.model_value
      Setting.set("temperature", pref.temperature.to_s)
      Setting.set("max_tokens", pref.max_tokens.to_s)

      redirect_to preferences_path, notice: "Preferences updated."
    end
  end
end
