# frozen_string_literal: true

require "test_helper"

module Notey
  class InAppDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

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
  end
end
