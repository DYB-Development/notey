# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Notey
  class InAppDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    include Turbo::Broadcastable::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:in_app, delivery_method: "Notey::InApp")
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    test "leaves the inbox record noticed already wrote and sends nothing further" do
      member = Member.create!(email: "person@example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_equal 1, Noticed::Notification.where(recipient: member).count
    end

    test "pushes the delivered notification to the recipient's stream when live updates are on" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      member = Member.create!(email: "person@example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_turbo_stream_broadcasts LiveInbox.stream(member, 7), count: 1
    end

    test "points a pushed row's Mark read at the url the host set" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/inbox/read" }
      member = Member.create!(email: "person@example.com")

      pushed = capture_turbo_stream_broadcasts(LiveInbox.stream(member, 7)) do
        perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }
      end

      assert_includes pushed.first.to_html, 'action="/inbox/read"'
    end

    test "pushes nothing when live updates are left off" do
      member = Member.create!(email: "person@example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_no_turbo_stream_broadcasts LiveInbox.stream(member, 7)
    end

    test "pushes a notification with no account to nobody" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      Current.account_id = nil
      member = Member.create!(email: "person@example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_no_turbo_stream_broadcasts LiveInbox.stream(member, nil).compact
    end
  end
end
