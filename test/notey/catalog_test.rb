# frozen_string_literal: true

require "test_helper"

module Notey
  class CatalogTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "names the channels a notification type can be delivered on" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: %w[email] }

      assert_equal %w[email sms], Notey.catalog.channels_for("comment")
    end
  end
end
