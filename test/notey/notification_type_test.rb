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

    test "sends a channel with the delivery method its registration named" do
      Notey.channel(:sms, delivery_method: "RecordingDeliveryMethod")
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_equal RecordingDeliveryMethod, type.delivery_methods[:sms].constant
    end

    test "refuses a call that omits information it requires" do
      assert_raises(Noticed::ValidationError) do
        CommentNotification.with(nothing: true).deliver(Member.create!)
      end
    end

    test "presents the name it declares as its title when it presents no other" do
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_equal "Comment", type.new(params: {}).title
    end

    test "presents no body unless it presents one of its own" do
      type = Class.new(Notey::Notification) { notey_type :comment }

      assert_nil type.new(params: {}).body
    end

    test "is one of the notification types the application has" do
      Class.new(Notey::Notification) { notey_type :comment }

      assert_includes Notey.notification_types, "comment"
    end
  end
end
