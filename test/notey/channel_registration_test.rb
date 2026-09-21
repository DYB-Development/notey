# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelRegistrationTest < ActiveSupport::TestCase
    setup { Notey.reset! }
    teardown { Notey.reset! }

    def registered(name)
      Notey.registered_channels.find { |channel| channel.name == name }
    end

    test "names a channel the application registered" do
      Notey.channel(:sms)

      assert_includes Notey.channels, "sms"
    end

    test "forgets the channels it registered when notey is reset" do
      Notey.channel(:sms)

      Notey.reset!

      refute_includes Notey.channels, "sms"
    end

    test "records the delivery method that sends a channel" do
      Notey.channel(:sms, delivery_method: "TwilioDeliveryMethod")

      assert_equal "TwilioDeliveryMethod", registered("sms").delivery_method
    end

    test "needs no address unless the registration says so" do
      Notey.channel(:sms)

      refute_predicate registered("sms"), :addressed?
    end

    test "records that a channel needs an address" do
      Notey.channel(:sms, addressed: true)

      assert_predicate registered("sms"), :addressed?
    end

    test "lists the channels the application registered without any notification type" do
      Notey.channel(:sms)

      assert_equal %w[email in_app sms], Notey.channels.sort
    end
  end
end
