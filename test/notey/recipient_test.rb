# frozen_string_literal: true

require "test_helper"

module Notey
  class RecipientTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

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

    test "falls back to the declared default for a type the person never set" do
      Notey.catalog { notification :comment, default: %w[email] }
      Current.account_id = 7

      assert_equal %w[email], Member.create!.channels_for("comment")
    end

    test "returns the declared default when no account is set" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[sms])
      Notey.catalog { notification :comment, default: %w[email] }

      assert_equal %w[email], member.channels_for("comment")
    end
  end
end
