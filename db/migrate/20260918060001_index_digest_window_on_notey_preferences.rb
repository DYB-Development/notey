# frozen_string_literal: true

class IndexDigestWindowOnNoteyPreferences < ActiveRecord::Migration[8.1]
  def change
    add_index :notey_preferences, :digest_window
  end
end
