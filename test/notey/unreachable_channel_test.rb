# frozen_string_literal: true

require "test_helper"

module Notey
  class UnreachableChannelTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.mailer_sender = "alerts@example.org"
      ActionMailer::Base.deliveries = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    test "records no failed attempt for a person with no email address" do
      perform_enqueued_jobs { CommentNotification.notify(Member.create!, comment_id: 1) }

      assert_empty Attempt.all
    end

    test "still emails a person who does have an email address" do
      perform_enqueued_jobs { CommentNotification.notify(Member.create!(email: "person@example.com"), comment_id: 1) }

      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end
end
