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

    test "sends on a channel to the address that person set" do
      member = Member.create!
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      notify(member)

      assert_equal [ "https://mine.example.com" ], RecordingDeliveryMethod.sent
    end

    test "never sends a person's notification to an address the account set" do
      Destination.create!(account_id: 7, channel: "recording", address: "https://account.example.com")

      notify(Member.create!)

      assert_empty RecordingDeliveryMethod.sent
    end

    test "sends nothing on a channel the person set no address for" do
      notify(Member.create!)

      assert_empty RecordingDeliveryMethod.sent
    end

    test "never uses one account's address for another account's notification" do
      member = Member.create!
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      notify(member, account_id: 8)

      assert_empty RecordingDeliveryMethod.sent
    end
  end
end
