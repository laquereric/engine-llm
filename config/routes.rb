# frozen_string_literal: true

EngineLlm::Engine.routes.draw do
  resources :conversations, only: %i[index show create destroy] do
    resources :messages, only: %i[create]
  end

  resource :settings, only: %i[show update]
  resource :preferences, only: %i[show update]

  root "conversations#index"
end
