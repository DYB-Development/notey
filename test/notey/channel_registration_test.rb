# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelRegistrationTest < ActiveSupport::TestCase
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
  end
end
