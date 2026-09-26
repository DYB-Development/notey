# frozen_string_literal: true

require "test_helper"

module Notey
  class LiveInboxTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "gives two people in one account different streams" do
      first = Member.create!(email: "first@example.com")
      second = Member.create!(email: "second@example.com")

      assert_not_equal LiveInbox.stream(first, 7), LiveInbox.stream(second, 7)
    end

    test "gives one person a different stream in each account" do
      member = Member.create!(email: "person@example.com")

      assert_not_equal LiveInbox.stream(member, 7), LiveInbox.stream(member, 8)
    end

    test "logs a failed push with the notification it was for" do
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      member = Member.create!(email: "person@example.com")
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: 7)
      notification = event.notifications.create!(recipient: member, account_id: 7)
      logged = StringIO.new

      Rails.logger.stub(:error, ->(message) { logged.puts(message) }) do
        Turbo::StreamsChannel.stub(:broadcast_replace_to, ->(*, **) { raise "the cable server is down" }) do
          LiveInbox.read(notification)
        end
      end

      assert_includes logged.string, "notification #{notification.id}"
    end
  end
end
