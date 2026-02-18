# frozen_string_literal: true

class CreateClProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_providers do |t|
      t.string  :name,         null: false
      t.string  :slug,         null: false
      t.string  :env_key,      null: false
      t.string  :api_base_url
      t.boolean :active,       null: false, default: true
      t.integer :position,     null: false, default: 0

      t.timestamps
    end

    add_index :cl_providers, :slug, unique: true
  end
end
