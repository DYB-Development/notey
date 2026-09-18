# frozen_string_literal: true

require "test_helper"

module Notey
  class PreferenceTest < ActiveSupport::TestCase
    test "stores the channels a person wants for a notification type in an account" do
      preference = Preference.create!(
        member: Member.create!,
        account_id: 1,
        notification_type: "comment",
        channels: %w[email]
      )

      assert_equal %w[email], preference.reload.channels
    end

    test "refuses a digest window that is not immediate, daily or weekly" do
      preference = Preference.new(member: Member.create!, account_id: 7,
        notification_type: "comment", channels: [], digest_window: "fortnightly")

      preference.valid?

      assert_includes preference.errors[:digest_window], "is not a window notey sends on"
    end
  end
end
