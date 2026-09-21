# frozen_string_literal: true

class CreateNoteyAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :notey_attempts do |t|
      t.references :notification, null: false, foreign_key: { to_table: :noticed_notifications, on_delete: :cascade }
      t.string :channel, null: false
      t.string :state, null: false, default: "claimed"
      t.text :failure

      t.timestamps
    end

    add_index :notey_attempts, %i[notification_id channel], unique: true, name: "index_notey_attempts_unique"
  end
end
