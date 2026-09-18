# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationDeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup { RecordingDeliveryMethod.sent = [] }

    teardown do
      Current.reset
      Notey.reset!
    end

    def notify(member, account_id: 7)
      Notey.catalog { notification :comment, channels: %w[recording], default: %w[recording] }
      Current.account_id = account_id
      perform_enqueued_jobs { HookNotifier.deliver(member) }
    end

    test "sends on a channel to the address that account stored" do
      Destination.create!(account_id: 7, channel: "recording", address: "https://seven.example.com")

      notify(Member.create!)

      assert_equal [ "https://seven.example.com" ], RecordingDeliveryMethod.sent
    end
  end
end
