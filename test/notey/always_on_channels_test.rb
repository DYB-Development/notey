# frozen_string_literal: true

require "test_helper"

module Notey
  class AlwaysOnChannelsTest < ActiveSupport::TestCase
    setup { Notey.reset! }
    teardown { Notey.reset! }

    test "has email and in-app without the application registering them" do
      assert_equal %w[email in_app], Notey.channels.sort
    end
  end
end
