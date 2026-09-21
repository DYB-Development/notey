# frozen_string_literal: true

require "test_helper"

module Notey
  class NoteyDecisionTest < ActiveSupport::TestCase
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

    test "sends nothing on a channel the recipient's stored preference leaves out" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: [])

      perform_enqueued_jobs { CommentNotification.with(comment_id: 1).deliver(member) }

      assert_empty Noticed::DeliveryMethods::Test.delivered
    end

    test "delivers on a channel the recipient's stored preference names" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[test])

      perform_enqueued_jobs { CommentNotification.with(comment_id: 1).deliver(member) }

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end

    test "delivers on the channels that are on before anyone chooses" do
      Notey.channel(:in_app, delivery_method: "RecordingDeliveryMethod")
      RecordingDeliveryMethod.sent = []

      perform_enqueued_jobs { CommentNotification.with(comment_id: 1).deliver(Member.create!) }

      assert_equal 1, RecordingDeliveryMethod.sent.size
    end

    test "sends nothing at the moment it happens when the recipient's window is daily" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment",
        channels: %w[test], digest_window: "daily")

      perform_enqueued_jobs { CommentNotification.with(comment_id: 1).deliver(member) }

      assert_empty Noticed::DeliveryMethods::Test.delivered
    end

    test "records a notification in the inbox whatever the decision says" do
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: [])

      perform_enqueued_jobs { CommentNotification.with(comment_id: 1).deliver(member) }

      assert_equal 1, Noticed::Notification.where(recipient: member).count
    end
  end
end
