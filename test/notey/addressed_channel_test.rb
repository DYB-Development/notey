# frozen_string_literal: true

require "test_helper"

module Notey
  class AddressedChannelTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)
      RecordingDeliveryMethod.sent = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def recipient_wanting_recording
      Member.create!(email: "person@example.com").tap do |member|
        Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[recording])
      end
    end

    test "sends nothing on an addressed channel the recipient set no address for" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting_recording, comment_id: 1) }

      assert_empty RecordingDeliveryMethod.sent
    end

    test "sends on an addressed channel the recipient set an address for" do
      member = recipient_wanting_recording
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_equal 1, RecordingDeliveryMethod.sent.size
    end

    test "sends nothing on an addressed channel the recipient does not want" do
      member = Member.create!(email: "person@example.com")
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: [])
      Destination.create!(account_id: 7, channel: "recording", member: member, address: "https://mine.example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_empty RecordingDeliveryMethod.sent
    end

    test "sends nothing to an address the account set rather than the person" do
      member = recipient_wanting_recording
      Destination.create!(account_id: 7, channel: "recording", address: "https://account.example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_empty RecordingDeliveryMethod.sent
    end
  end
end
