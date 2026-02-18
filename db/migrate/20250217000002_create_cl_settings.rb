# frozen_string_literal: true

class CreateClSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_settings do |t|
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :cl_settings, :key, unique: true
  end
end
