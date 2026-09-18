# frozen_string_literal: true

class CreateNoteyPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notey_preferences do |t|
      t.references :member, polymorphic: true, null: false
      t.bigint :account_id, null: false
      t.string :notification_type, null: false
      t.json :channels, null: false, default: []

      t.timestamps
    end

    add_index :notey_preferences, %i[member_type member_id account_id notification_type],
      unique: true, name: "index_notey_preferences_unique"
  end
end
