# frozen_string_literal: true

class CreateClProviderModels < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_provider_models do |t|
      t.references :provider, null: false, foreign_key: { to_table: :cl_providers }
      t.string  :value,    null: false
      t.string  :label,    null: false
      t.integer :position, null: false, default: 0
      t.boolean :active,   null: false, default: true
      t.boolean :free,     null: false, default: false

      t.timestamps
    end

    add_index :cl_provider_models, :value, unique: true
  end
end
