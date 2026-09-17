# frozen_string_literal: true

class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.timestamps
    end
  end
end
