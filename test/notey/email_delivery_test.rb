# frozen_string_literal: true

require "test_helper"

module Notey
  class EmailDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:email, delivery_method: "Notey::Email")
      Notey.mailer_sender = "alerts@example.org"
      ActionMailer::Base.deliveries = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    test "emails the person the notification is for" do
      member = Member.create!(email: "person@example.com")

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_equal [ "person@example.com" ], ActionMailer::Base.deliveries.last&.to
    end
  end
end
