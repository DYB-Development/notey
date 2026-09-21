# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelCheckTest < ActiveSupport::TestCase
    setup { Notey.reset! }
    teardown { Notey.reset! }

    test "refuses a channel whose delivery method does not exist" do
      Notey.channel(:carrier_pigeon, delivery_method: "NoSuchDeliveryMethod")

      error = assert_raises(Notey::UnsendableChannel) { Notey.check! }

      assert_match(/carrier_pigeon/, error.message)
    end

    test "refuses a channel whose delivery method requires an option notey cannot supply" do
      Notey.channel(:newsletter, delivery_method: "Noticed::DeliveryMethods::Email")

      error = assert_raises(Notey::UnsendableChannel) { Notey.check! }

      assert_match(/mailer/, error.message)
    end
  end
end
