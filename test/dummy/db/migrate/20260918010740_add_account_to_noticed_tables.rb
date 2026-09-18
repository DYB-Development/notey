# frozen_string_literal: true

class AddAccountToNoticedTables < ActiveRecord::Migration[8.1]
  def change
    add_column :noticed_events, :account_id, :bigint
    add_column :noticed_notifications, :account_id, :bigint
  end
end
