# frozen_string_literal: true

require "test_helper"

module Notey
  class DigestRunTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    teardown do
      Current.reset
      Notey.reset!
    end

    def member_with_daily_comment
      Notey.catalog { notification :comment, channels: %w[email], default: [] }
      member = Member.create!(email: "person@example.com")
      Preference.create!(member: member, account_id: 7, notification_type: "comment",
        channels: %w[email], digest_window: "daily")
      member
    end

    def notify(member, count)
      Current.account_id = 7
      count.times { perform_enqueued_jobs { CommentNotifier.deliver(member) } }
    end

    test "sends one email covering a person's window" do
      member = member_with_daily_comment
      notify(member, 2)

      assert_emails 1 do
        DigestRun.new(window: "daily").call
      end
    end
  end
end
