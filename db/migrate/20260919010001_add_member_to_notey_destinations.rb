# frozen_string_literal: true

class AddMemberToNoteyDestinations < ActiveRecord::Migration[8.1]
  def change
    add_reference :notey_destinations, :member, polymorphic: true, null: true

    remove_index :notey_destinations, %i[account_id channel]
    add_index :notey_destinations, %i[member_type member_id account_id channel],
      unique: true, name: "index_notey_destinations_unique"
  end
end
