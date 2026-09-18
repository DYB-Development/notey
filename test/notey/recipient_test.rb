# frozen_string_literal: true

require "test_helper"

module Notey
  class RecipientTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "reports a channel the person stored for the account they are in" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[email])
      Current.account_id = 7

      assert member.wants?("comment", on: "email")
    end

    test "holds different channels for the same person in two accounts" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: [] }
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

    test "arrives immediately for a person who has set nothing" do
      Current.account_id = 7

      assert_equal "immediate", Member.create!.digest_window_for("comment")
    end

    test "ignores a stored preference for a type the catalog no longer holds" do
      Notey.catalog { notification :comment, channels: %w[email], default: %w[email] }
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "retired", channels: %w[email])
      Current.account_id = 7

      assert_empty member.channels_for("retired")
    end

    test "reads channels through the one resolver" do
      member = Member.create!
      Current.account_id = 7

      Channels.stub(:for, ->(*, **) { %w[carrier-pigeon] }) do
        assert_equal %w[carrier-pigeon], member.channels_for("comment")
      end
    end

    test "reads the window through the one resolver" do
      member = Member.create!
      Current.account_id = 7

      Channels.stub(:window_for, ->(*, **) { "fortnightly" }) do
        assert_equal "fortnightly", member.digest_window_for("comment")
      end
    end
  end
end
