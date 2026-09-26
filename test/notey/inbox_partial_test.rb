# frozen_string_literal: true

require "test_helper"

module Notey
  class InboxPartialTest < ActionView::TestCase
    helper KeystoneUiHelper
    helper Turbo::StreamsHelper

    teardown { Notey.reset! }

    def notification_for(member, account_id: 7)
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: account_id)
      event.notifications.create!(recipient: member, account_id: account_id)
    end

    def draw(person:, account: 7)
      render partial: "notey/inbox", locals: { person: person, account: account, submit_url: "/notifications" }
    end

    test "lists the notifications a person received in the account they are in" do
      member = Member.create!(email: "person@example.com")
      notification_for(member)

      draw(person: member)

      assert_select "[data-notification-id]", 1
    end

    test "leaves out the notifications a person received in another account" do
      member = Member.create!(email: "person@example.com")
      notification_for(member, account_id: 8)

      draw(person: member)

      assert_select "[data-notification-id]", 0
    end

    test "marks a notification the person has not read as unread" do
      member = Member.create!(email: "person@example.com")
      notification_for(member)

      draw(person: member)

      assert_select "[data-notification-id]", text: /Unread/
    end

    test "offers to mark an unread notification read on the page the host names" do
      member = Member.create!(email: "person@example.com")
      notification_for(member)

      draw(person: member)

      assert_select "form[action='/notifications']"
    end

    test "stops showing a notification as unread once it is read" do
      member = Member.create!(email: "person@example.com")
      notification_for(member).mark_as_read!

      draw(person: member)

      assert_select "[data-notification-id]", text: /Read/
    end

    test "subscribes the page to live updates when the host turns them on" do
      Notey.live_updates = true
      member = Member.create!(email: "person@example.com")

      draw(person: member)

      assert_select "turbo-cable-stream-source", 1
    end

    test "subscribes the page to the stream of the person in the account they are in" do
      Notey.live_updates = true
      member = Member.create!(email: "person@example.com")

      draw(person: member)

      assert_select "turbo-cable-stream-source[signed-stream-name=?]",
        Turbo::StreamsChannel.signed_stream_name(LiveInbox.stream(member, 7))
    end

    test "subscribes the page to nothing when no account is given" do
      Notey.live_updates = true
      member = Member.create!(email: "person@example.com")

      draw(person: member, account: nil)

      assert_select "turbo-cable-stream-source", 0
    end

    test "subscribes the page to nothing while live updates are left off" do
      member = Member.create!(email: "person@example.com")

      draw(person: member)

      assert_select "turbo-cable-stream-source", 0
    end
  end
end
