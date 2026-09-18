# frozen_string_literal: true

class CreateNoteyDigests < ActiveRecord::Migration[8.1]
  def change
    create_table :notey_digests do |t|
      t.references :member, polymorphic: true, null: false
      t.bigint :account_id, null: false
      t.string :digest_window, null: false
      t.integer :notifications_count, null: false, default: 0
      t.datetime :sent_at

      t.timestamps
    end
  end
end
