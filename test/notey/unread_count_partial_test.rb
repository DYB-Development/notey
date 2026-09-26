# frozen_string_literal: true

require "test_helper"

module Notey
  class UnreadCountPartialTest < ActionView::TestCase
    teardown { Notey.reset! }

    def notification_for(member, account_id: 7)
      event = CommentNotification.create!(params: { comment_id: 1 }, account_id: account_id)
      event.notifications.create!(recipient: member, account_id: account_id)
    end

    test "shows how many notifications the person has not read in the account they are in" do
      member = Member.create!(email: "person@example.com")
      2.times { notification_for(member) }

      render partial: "notey/unread_count", locals: { person: member, account: 7 }

      assert_select "#notey_unread_count", text: "2"
    end
  end
end
