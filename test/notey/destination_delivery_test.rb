# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)
      RecordingDeliveryMethod.sent = []
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def notify(member, account_id: 7)
      Current.account_id = account_id
      Preference.find_or_create_by!(member: member, account_id: account_id, notification_type: "comment")
        .update!(channels: %w[recording])
      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }
    end

    test "sends on a channel to the address that person set" do
      member = Member.create!(email: "person@example.com")
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      notify(member)

      assert_equal [ "https://mine.example.com" ], RecordingDeliveryMethod.sent
    end

    test "never sends a person's notification to an address the account set" do
      Destination.create!(account_id: 7, channel: "recording", address: "https://account.example.com")

      notify(Member.create!(email: "person@example.com"))

      assert_empty RecordingDeliveryMethod.sent
    end

    test "sends nothing on a channel the person set no address for" do
      notify(Member.create!(email: "person@example.com"))

      assert_empty RecordingDeliveryMethod.sent
    end

    test "never uses one account's address for another account's notification" do
      member = Member.create!(email: "person@example.com")
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      notify(member, account_id: 8)

      assert_empty RecordingDeliveryMethod.sent
    end
  end
end
