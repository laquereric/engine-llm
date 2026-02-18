# frozen_string_literal: true

class CreateClPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_preferences do |t|
      t.references :default_model,      foreign_key: { to_table: :cl_provider_models }
      t.references :preferred_provider,  foreign_key: { to_table: :cl_providers }
      t.decimal :temperature, precision: 3, scale: 1, null: false, default: 0.7
      t.integer :max_tokens,  null: false, default: 4096

      t.timestamps
    end
  end
end
