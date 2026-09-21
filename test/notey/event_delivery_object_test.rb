# frozen_string_literal: true

require "test_helper"

module Notey
  class EventDeliveryObjectTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    Event = Struct.new(:event_name, :payload, keyword_init: true)

    setup { RecordingDeliveryMethod.sent = [] }

    teardown do
      Current.reset
      Notey.reset!
    end

    test "delivers the notifier mapped to an event" do
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      member = Member.create!
      Notey.deliver_on :thing_happened, ThingHappenedNotifier

      perform_enqueued_jobs do
        EventDelivery.call(Event.new(event_name: :thing_happened,
          payload: { account_id: 7, member_ids: [ member.id ] }))
      end

      assert_equal 1, RecordingDeliveryMethod.sent.size
    end
  end
end
