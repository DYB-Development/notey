# frozen_string_literal: true

require "test_helper"

module Notey
  class RecipientTest < ActiveSupport::TestCase
    teardown { Current.reset }

    test "reports a channel the person stored for the account they are in" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[email])
      Current.account_id = 7

      assert member.wants?("comment", on: "email")
    end
  end
end
