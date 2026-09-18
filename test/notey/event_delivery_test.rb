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

    test "delivers the notifier mapped to a domain event" do
      declared_comment
      member = Member.create!
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        EventSubscriber.new.handle(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end
  end
end
