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

    test "is delivered on a channel registered after it was defined" do
      type = Class.new(Notey::Notification) { notey_type :comment }

      Notey.channel(:sms)

      assert_equal %i[sms], type.delivery_methods.keys
    end
  end
end
