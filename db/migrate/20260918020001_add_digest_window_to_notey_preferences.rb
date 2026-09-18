# frozen_string_literal: true

class AddDigestWindowToNoteyPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :notey_preferences, :digest_window, :string, null: false, default: "immediate"
  end
end
