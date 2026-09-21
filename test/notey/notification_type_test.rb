# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationTypeTest < ActiveSupport::TestCase
    setup { Notey.reset! }
    teardown { Notey.reset! }

    test "keys stored preferences by the name it declares rather than its class name" do
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_equal "comment", type.notey_notification_type
    end

    test "is delivered on every channel the application registered" do
      Notey.channel(:email)
      Notey.channel(:sms)
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_equal %i[email sms], type.delivery_methods.keys.sort
    end
  end
end
