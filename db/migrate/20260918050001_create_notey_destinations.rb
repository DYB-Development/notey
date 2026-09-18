# frozen_string_literal: true

class CreateNoteyDestinations < ActiveRecord::Migration[8.1]
  def change
    create_table :notey_destinations do |t|
      t.bigint :account_id, null: false
      t.string :channel, null: false
      t.string :address, null: false
      t.text :credential

      t.timestamps
    end

    add_index :notey_destinations, %i[account_id channel], unique: true
  end
end
