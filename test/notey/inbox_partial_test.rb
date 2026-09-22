# frozen_string_literal: true

require "test_helper"

module Notey
  class InboxPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

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
  end
end
