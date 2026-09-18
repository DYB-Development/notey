# frozen_string_literal: true

class AddPeriodStartToNoteyDigests < ActiveRecord::Migration[8.1]
  def change
    add_column :notey_digests, :period_start, :datetime, null: false

    add_index :notey_digests,
      %i[member_type member_id account_id digest_window period_start],
      unique: true, name: "index_notey_digests_unique"
  end
end
