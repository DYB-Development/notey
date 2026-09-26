# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Notey
  class MarkReadTest < ActiveSupport::TestCase
    include Turbo::Broadcastable::TestHelper

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

    test "replaces the read row in the person's other open pages when live updates are on" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      member = Member.create!(email: "person@example.com")
      notification = notification_for(member)

      pushed = capture_turbo_stream_broadcasts(LiveInbox.stream(member, 7)) do
        MarkRead.new(person: member, account: 7, values: { read: notification.id }).call
      end

      assert pushed.any? { |stream| stream["action"] == "replace" && stream["target"] == "notey_notification_#{notification.id}" }
    end

    test "pushes the lower unread count when a notification is read" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      member = Member.create!(email: "person@example.com")
      notification = notification_for(member)

      pushed = capture_turbo_stream_broadcasts(LiveInbox.stream(member, 7)) do
        MarkRead.new(person: member, account: 7, values: { read: notification.id }).call
      end

      assert_includes pushed.map(&:to_html).join, '<span id="notey_unread_count">0</span>'
    end
  end
end
