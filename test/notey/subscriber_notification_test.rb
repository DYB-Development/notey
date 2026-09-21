# frozen_string_literal: true

require "test_helper"

module Notey
  class SubscriberNotificationTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    Event = Struct.new(:event_name, :payload, keyword_init: true)

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:webhook, delivery_method: "RecordingDeliveryMethod")
      RecordingDeliveryMethod.sent = []
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def thing_happened(member_ids:, account_id: 7)
      Event.new(event_name: :thing_happened,
        payload: { account_id: account_id, member_ids: member_ids, comment_id: 1 })
    end

    def recipient_wanting(*channels)
      Member.create!(email: "person@example.com").tap do |member|
        Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: channels.map(&:to_s))
      end
    end

    test "sends a notification to the recipients a subscriber resolved" do
      member = recipient_wanting(:webhook)

      perform_enqueued_jobs { NoteyNotifications.new.handle(thing_happened(member_ids: [ member.id ])) }

      assert_equal 1, RecordingDeliveryMethod.sent.size
    end

    test "records the notification against the account the event names" do
      member = recipient_wanting(:webhook)

      perform_enqueued_jobs { NoteyNotifications.new.handle(thing_happened(member_ids: [ member.id ])) }

      assert_equal 7, Noticed::Notification.last.account_id
    end

    test "sends nothing on a channel the recipient turned off" do
      member = recipient_wanting

      perform_enqueued_jobs { NoteyNotifications.new.handle(thing_happened(member_ids: [ member.id ])) }

      assert_empty RecordingDeliveryMethod.sent
    end

    test "sends nothing for an event no subscriber handles" do
      member = recipient_wanting(:webhook)

      perform_enqueued_jobs do
        EventEngine::Subscribers::Registry.subscribers_for(:nobody_handles_this).each do |subscriber|
          subscriber.new.handle(thing_happened(member_ids: [ member.id ]))
        end
      end

      assert_empty RecordingDeliveryMethod.sent
    end
  end
end
