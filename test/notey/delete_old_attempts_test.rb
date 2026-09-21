# frozen_string_literal: true

require "test_helper"

module Notey
  class DeleteOldAttemptsTest < ActiveSupport::TestCase
    setup do
      Notey.reset!
      Notey.attempt_retention = 30.days
    end

    teardown do
      Notey.attempt_retention = nil
      Notey.reset!
    end

    def attempt_recorded(days_ago)
      member = Member.create!(email: "person@example.com")
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: 7)
      notification = event.notifications.create!(recipient: member)
      Attempt.create!(notification: notification, channel: "webhook", state: "sent",
        created_at: days_ago.days.ago)
    end

    test "deletes a record older than the period the host keeps" do
      attempt_recorded(31)

      DeleteOldAttempts.new.call

      assert_empty Attempt.all
    end

    test "keeps a record inside the period the host keeps" do
      attempt_recorded(29)

      DeleteOldAttempts.new.call

      assert_equal 1, Attempt.count
    end
  end
end
