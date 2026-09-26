# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

module Notey
  class NotificationsTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper
    include ActiveRecord::Assertions::QueryAssertions
    include Turbo::Broadcastable::TestHelper

    teardown do
      Current.reset
      Notey.reset!
    end

    def headers_for(member, account_id: 7)
      { "X-Member-Id" => member.id.to_s, "X-Account-Id" => account_id.to_s }
    end

    def notify(member, account_id: 7)
      Current.account_id = account_id
      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }
      Current.reset
    end

    test "does not query more as the list grows" do
      member = Member.create!(email: "person@example.com")
      3.times { notify(member) }
      get "/notey/notifications", headers: headers_for(member)
      baseline = count_queries { get "/notey/notifications", headers: headers_for(member) }

      3.times { notify(member) }

      assert_queries_count baseline do
        get "/notey/notifications", headers: headers_for(member)
      end
    end

    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    test "refuses to mark read a notification held in another account" do
      member = Member.create!(email: "person@example.com")
      notify(member, account_id: 8)

      patch "/notey/notifications/#{Noticed::Notification.last.id}",
        headers: headers_for(member, account_id: 7)

      assert Noticed::Notification.last.unread?
    end

    test "lists at most one page of notifications" do
      member = Member.create!(email: "person@example.com")
      (Notey::NotificationsController::PER_PAGE + 1).times { notify(member) }

      get "/notey/notifications", headers: headers_for(member)

      assert_select "[data-notification-id]", Notey::NotificationsController::PER_PAGE
    end

    test "leaves a notification past the first page unseen" do
      member = Member.create!(email: "person@example.com")
      (Notey::NotificationsController::PER_PAGE + 1).times { notify(member) }

      get "/notey/notifications", headers: headers_for(member)

      assert Noticed::Notification.order(:created_at).first.unseen?
    end

    test "lists the notifications addressed to a person in the account they are in" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "[data-notification-id]", 1
    end

    test "leaves out a notification belonging to another of that person's accounts" do
      member = Member.create!(email: "person@example.com")
      notify(member, account_id: 8)

      get "/notey/notifications", headers: headers_for(member, account_id: 7)

      assert_select "[data-notification-id]", 0
    end

    test "marks the listed notifications as seen" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert Noticed::Notification.last.seen?
    end

    test "shows a notification as read after a person marks it" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      patch "/notey/notifications/#{Noticed::Notification.last.id}", headers: headers_for(member)

      assert Noticed::Notification.last.read?
    end

    test "shows how many notifications are unread in the current account" do
      member = Member.create!(email: "person@example.com")
      notify(member)
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "body", text: /2 unread/
    end

    test "lists what the one relation holds and nothing else" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      Inbox.stub(:for, ->(*) { Noticed::Notification.none }) do
        get "/notey/notifications", headers: headers_for(member)
      end

      assert_select "[data-notification-id]", 0
    end

    test "counts unread from the one relation and nothing else" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      Inbox.stub(:for, ->(*) { Noticed::Notification.none }) do
        get "/notey/notifications", headers: headers_for(member)
      end

      assert_select "body", text: /0 unread/
    end

    test "counts no unread when no account is set" do
      member = Member.create!(email: "person@example.com")
      notify(member)
      Noticed::Notification.last.update_column(:account_id, nil)

      get "/notey/notifications", headers: { "X-Member-Id" => member.id.to_s }

      assert_select "body", text: /0 unread/
    end

    test "lists nothing when no account is set" do
      member = Member.create!(email: "person@example.com")
      notify(member)
      Noticed::Notification.last.update_column(:account_id, nil)

      get "/notey/notifications", headers: { "X-Member-Id" => member.id.to_s }

      assert_select "[data-notification-id]", 0
    end

    test "replaces a row read on this page in the person's other open pages" do
      member = Member.create!(email: "person@example.com")
      notify(member)
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }
      notification = Noticed::Notification.last

      pushed = capture_turbo_stream_broadcasts(LiveInbox.stream(member, 7)) do
        patch "/notey/notifications/#{notification.id}", headers: headers_for(member)
      end

      assert pushed.any? { |stream| stream["target"] == "notey_notification_#{notification.id}" }
    end

    test "subscribes the page to the person's stream when live updates are on" do
      Notey.live_updates = true
      member = Member.create!(email: "person@example.com")

      get "/notey/notifications", headers: headers_for(member)

      assert_select "turbo-cable-stream-source[signed-stream-name=?]",
        Turbo::StreamsChannel.signed_stream_name(LiveInbox.stream(member, "7"))
    end

    test "shows the unread count where a live update can replace it" do
      member = Member.create!(email: "person@example.com")
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "#notey_unread_count", text: "1"
    end
  end
end
