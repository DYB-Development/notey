# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelRegistrationTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "names a channel the application registered" do
      Notey.channel(:sms)

      assert_equal %w[sms], Notey.registered_channels.map(&:name)
    end
  end
end
