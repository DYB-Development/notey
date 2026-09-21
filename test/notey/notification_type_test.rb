# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationTypeTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "keys stored preferences by the name it declares rather than its class name" do
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_equal "comment", type.notey_notification_type
    end
  end
end
