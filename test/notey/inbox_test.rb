# frozen_string_literal: true

require "test_helper"

module Notey
  class InboxTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    teardown do
      Current.reset
      Notey.reset!
    end

    def notified_member(account_id: 7)
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      member = Member.create!(email: "person@example.com")
      Current.account_id = account_id
      perform_enqueued_jobs { CommentNotifier.deliver(member) }
      member
    end

    test "holds a person's notifications for one account" do
      member = notified_member

      assert_equal 1, Inbox.for(member, account_id: 7).count
    end

    test "holds nothing when no account is set" do
      member = notified_member
      Noticed::Notification.last.update_column(:account_id, nil)

      assert_equal 0, Inbox.for(member, account_id: nil).count
    end
  end
end
