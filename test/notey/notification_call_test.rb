# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationCallTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:test, delivery_method: "Noticed::DeliveryMethods::Test")
      Noticed::DeliveryMethods::Test.delivered = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    test "sends a notification to the recipient it is called with" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[test])

      perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) }

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end

    test "records one notification for each of many recipients" do
      members = Array.new(3) { Member.create! }

      CommentNotification.notify(members, comment_id: 1)

      assert_equal 3, Noticed::Notification.where(recipient: members).count
    end
  end
end
