# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup { RecordingDeliveryMethod.sent = [] }

    teardown do
      Current.reset
      Notey.reset!
    end

    def notify(member, account_id: 7)
      Notey.catalog { notification :comment, channels: %w[recording], default: %w[recording] }
      Current.account_id = account_id
      perform_enqueued_jobs { HookNotifier.deliver(member) }
    end

    test "sends on a channel to the address that account stored" do
      Destination.create!(account_id: 7, channel: "recording", address: "https://seven.example.com")

      notify(Member.create!)

      assert_equal [ "https://seven.example.com" ], RecordingDeliveryMethod.sent
    end

    test "sends to the address the person stored over the account's" do
      member = Member.create!
      Destination.create!(account_id: 7, channel: "recording", address: "https://account.example.com")
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      notify(member)

      assert_equal [ "https://mine.example.com" ], RecordingDeliveryMethod.sent
    end

    test "sends nothing on a channel the account stored no destination for" do
      notify(Member.create!)

      assert_empty RecordingDeliveryMethod.sent
    end

    test "never uses one account's destination for another account's notification" do
      Destination.create!(account_id: 7, channel: "recording", address: "https://seven.example.com")

      notify(Member.create!, account_id: 8)

      assert_empty RecordingDeliveryMethod.sent
    end
  end
end
