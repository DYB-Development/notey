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

    def deliver_ignoring_failure(&block)
      perform_enqueued_jobs(&block)
    rescue Minitest::UnexpectedError
      nil
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

    test "records a failure and what it said when a send raises" do
      Notey.channel(:failing, delivery_method: "FailingDeliveryMethod")
      member = recipient_wanting(:failing)

      deliver_ignoring_failure { CommentNotification.notify(member, comment_id: 1) }

      assert_equal [ "failed", "the provider refused it" ], Attempt.last.then { |a| [ a.state, a.failure ] }
    end

    test "records nothing for a channel the send decision refused" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting(:webhook), comment_id: 1) }

      assert_equal %w[webhook], Attempt.pluck(:channel)
    end

    test "records nothing for a person's in-app notification" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting(:in_app), comment_id: 1) }

      assert_empty Attempt.all
    end

    test "sends nothing the second time the same notification goes on the same channel" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting(:webhook), comment_id: 1) }
      notification = Noticed::Notification.last

      perform_enqueued_jobs { CommentNotification.delivery_methods[:webhook].perform_later(notification) }

      assert_equal 1, RecordingDeliveryMethod.sent.size
    end

    test "loses the records of what was sent when the notification is deleted" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_wanting(:webhook), comment_id: 1) }

      Noticed::Notification.last.destroy

      assert_empty Attempt.all
    end
  end
end
