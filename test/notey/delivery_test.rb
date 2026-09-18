# frozen_string_literal: true

require "test_helper"

module Notey
  class DeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup { Noticed::DeliveryMethods::Test.delivered = [] }

    teardown do
      Current.reset
      Notey.reset!
    end

    test "does not deliver on a channel the recipient turned off" do
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: [])
      Current.account_id = 7

      perform_enqueued_jobs { CommentNotifier.deliver(member) }

      assert_empty Noticed::DeliveryMethods::Test.delivered
    end
  end
end
