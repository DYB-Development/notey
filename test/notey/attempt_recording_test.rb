# frozen_string_literal: true

require "test_helper"

module Notey
  class AttemptRecordingTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:webhook, delivery_method: "RecordingDeliveryMethod")
      RecordingDeliveryMethod.sent = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def recipient_wanting(*channels)
      Member.create!(email: "person@example.com").tap do |member|
        Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: channels.map(&:to_s))
      end
    end

    test "records the channel it sent on and that it was sent" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting(:webhook), comment_id: 1) }

      assert_equal [ "webhook", "sent" ], Attempt.last&.then { |a| [ a.channel, a.state ] }
    end
  end
end
