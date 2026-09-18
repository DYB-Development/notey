# frozen_string_literal: true

require "test_helper"

module Notey
  class EventDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    Event = Struct.new(:event_name, :payload, keyword_init: true)

    setup { Noticed::DeliveryMethods::Test.delivered = [] }

    teardown do
      Current.reset
      Notey.reset!
    end

    def declared_comment
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
    end

    test "reaches notey through a subscriber the host owns" do
      declared_comment
      member = Member.create!
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        NoteyNotifications.new.handle(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end

    test "puts back the account that was set before the event" do
      declared_comment
      Notey.deliver_on :thing_happened, ThingHappenedNotifier
      Current.account_id = 99

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [] }))
      end

      assert_equal 99, Current.account_id
    end

    test "delivers the notifier mapped to a domain event" do
      declared_comment
      member = Member.create!
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end

    test "scopes the notification to the account named on the event" do
      declared_comment
      member = Member.create!
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_equal 7, Noticed::Notification.last.account_id
    end

    test "delivers nothing and raises nothing for an unmapped domain event" do
      declared_comment
      member = Member.create!

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :nobody_mapped_this,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_empty Noticed::DeliveryMethods::Test.delivered
    end

    test "honours the recipient's channel preferences" do
      declared_comment
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: [])
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_empty Noticed::DeliveryMethods::Test.delivered
    end
  end
end
