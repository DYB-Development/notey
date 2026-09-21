# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelRegistrationTest < ActiveSupport::TestCase
    setup { Notey.reset! }
    teardown { Notey.reset! }

    test "names a channel the application registered" do
      Notey.channel(:sms)

      assert_equal %w[sms], Notey.registered_channels.map(&:name)
    end

    test "forgets the channels it registered when notey is reset" do
      Notey.channel(:sms)

      Notey.reset!

      assert_empty Notey.registered_channels
    end

    test "records the delivery method that sends a channel" do
      Notey.channel(:sms, delivery_method: "TwilioDeliveryMethod")

      assert_equal "TwilioDeliveryMethod", Notey.registered_channels.first.delivery_method
    end

    test "needs no address unless the registration says so" do
      Notey.channel(:in_app)

      refute_predicate Notey.registered_channels.first, :addressed?
    end

    test "records that a channel needs an address" do
      Notey.channel(:sms, addressed: true)

      assert_predicate Notey.registered_channels.first, :addressed?
    end

    test "records the options the delivery method requires" do
      Notey.channel(:sms, delivery_method: "TwilioDeliveryMethod", options: { from: "+15550000" })

      assert_equal({ from: "+15550000" }, Notey.registered_channels.first.options)
    end

    test "lists the channels the application registered without any notification type" do
      Notey.channel(:email)
      Notey.channel(:sms)

      assert_equal %w[email sms], Notey.channels.sort
    end
  end
end
