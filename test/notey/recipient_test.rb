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

    test "holds different channels for the same person in two accounts" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[email])
      Preference.create!(member: member, account_id: 8, notification_type: "comment", channels: %w[sms])
      Current.account_id = 8

      assert_equal %w[sms], member.channels_for("comment")
    end
  end
end
