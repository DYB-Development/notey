# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationMailerTest < ActionMailer::TestCase
    teardown { Notey.reset! }

    test "titles the email with the title the notification type presents" do
      Notey.mailer_sender = "alerts@example.org"
      member = Member.create!(email: "person@example.com")
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: 7)
      notification = event.notifications.create!(recipient: member)

      mail = NotificationMailer.with(notification: notification, recipient: member).notification

      assert_equal "Comment", mail.subject
    end

    test "shows the body the notification type presents" do
      Notey.mailer_sender = "alerts@example.org"
      member = Member.create!(email: "person@example.com")
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: 7)
      notification = event.notifications.create!(recipient: member)

      mail = NotificationMailer.with(notification: notification, recipient: member).notification

      assert_match "Comment 1 was left for you", mail.body.to_s
    end
  end
end
