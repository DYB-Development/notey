# frozen_string_literal: true

require "test_helper"

module Notey
  class DroppedChannelTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:webhook, delivery_method: "RecordingDeliveryMethod")
      RecordingDeliveryMethod.sent = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def recipient_stored_with(*channels)
      Member.create!(email: "person@example.com").tap do |member|
        preference = Preference.new(member: member, account_id: 7, notification_type: "comment",
          channels: channels.map(&:to_s))
        preference.save(validate: false)
      end
    end

    test "keeps only the channels the application still has" do
      member = recipient_stored_with(:webhook, :carrier_pigeon)

      assert_equal %w[webhook], Channels.for(member, "comment", account_id: 7)
    end
  end
end
