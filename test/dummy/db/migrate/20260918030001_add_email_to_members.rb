# frozen_string_literal: true

class AddEmailToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :email, :string
  end
end
