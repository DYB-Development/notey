# frozen_string_literal: true

require "test_helper"

module Notey
  class SendAgainTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:flaky, delivery_method: "FailingDeliveryMethod")
      FailingDeliveryMethod.failing = true
      FailingDeliveryMethod.sent = []
      Current.account_id = 7
    end

    teardown do
      FailingDeliveryMethod.failing = true
      Current.reset
      Notey.reset!
    end

    def failed_attempt
      member = Member.create!(email: "person@example.com")
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[flaky])
      begin
        perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }
      rescue Minitest::UnexpectedError
        nil
      end
      Attempt.last
    end

    test "sends again on the one channel a failed attempt names" do
      attempt = failed_attempt
      FailingDeliveryMethod.failing = false

      perform_enqueued_jobs { attempt.send_again }

      assert_equal 1, FailingDeliveryMethod.sent.size
    end

    test "records an attempt that was sent again as sent" do
      attempt = failed_attempt
      FailingDeliveryMethod.failing = false

      perform_enqueued_jobs { attempt.send_again }

      assert_equal "sent", Attempt.last.state
    end
  end
end
