# frozen_string_literal: true

require "test_helper"

module Notey
  class DeliveredChannelsTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "holds every channel the notifiers deliver on" do
      Notey.register_notifier(notifier_delivering(:comment, :email))
      Notey.register_notifier(notifier_delivering(:mention, :sms))

      assert_equal %w[email sms], Notey.channels.sort
    end
  end
end
