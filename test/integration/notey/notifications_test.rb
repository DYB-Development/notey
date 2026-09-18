# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationsTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    teardown do
      Current.reset
      Notey.reset!
    end

    def headers_for(member, account_id: 7)
      { "X-Member-Id" => member.id.to_s, "X-Account-Id" => account_id.to_s }
    end

    def notify(member, account_id: 7)
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      Current.account_id = account_id
      perform_enqueued_jobs { CommentNotifier.deliver(member) }
      Current.reset
    end

    test "lists the notifications addressed to a person in the account they are in" do
      member = Member.create!
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "[data-notification-id]", 1
    end

    test "leaves out a notification belonging to another of that person's accounts" do
      member = Member.create!
      notify(member, account_id: 8)

      get "/notey/notifications", headers: headers_for(member, account_id: 7)

      assert_select "[data-notification-id]", 0
    end

    test "marks the listed notifications as seen" do
      member = Member.create!
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert Noticed::Notification.last.seen?
    end

    test "shows a notification as read after a person marks it" do
      member = Member.create!
      notify(member)

      patch "/notey/notifications/#{Noticed::Notification.last.id}", headers: headers_for(member)

      assert Noticed::Notification.last.read?
    end

    test "shows how many notifications are unread in the current account" do
      member = Member.create!
      notify(member)
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "body", text: /2 unread/
    end

    test "lists what the one relation holds and nothing else" do
      member = Member.create!
      notify(member)

      Inbox.stub(:for, ->(*) { Noticed::Notification.none }) do
        get "/notey/notifications", headers: headers_for(member)
      end

      assert_select "[data-notification-id]", 0
    end
  end
end
