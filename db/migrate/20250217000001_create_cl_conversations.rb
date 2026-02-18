# frozen_string_literal: true

class CreateClConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :cl_conversations do |t|
      t.string :title, null: false
      t.text :transcript, default: "[]"
      t.string :model

      t.timestamps
    end
  end
end
