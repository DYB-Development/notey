# frozen_string_literal: true

require "test_helper"

module Notey
  class MarkReadTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    def notification_for(member, account_id: 7)
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: account_id)
      event.notifications.create!(recipient: member, account_id: account_id)
    end

    test "marks the notification the person picked as read" do
      member = Member.create!(email: "person@example.com")
      notification = notification_for(member)

      MarkRead.new(person: member, account: 7, values: { read: notification.id }).call

      assert_predicate notification.reload, :read?
    end

    test "never marks a notification another account holds" do
      member = Member.create!(email: "person@example.com")
      notification = notification_for(member, account_id: 8)

      MarkRead.new(person: member, account: 7, values: { read: notification.id }).call

      assert_not notification.reload.read?
    end
  end
end
