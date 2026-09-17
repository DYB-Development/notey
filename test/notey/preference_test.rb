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
  end
end
