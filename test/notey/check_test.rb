# frozen_string_literal: true

require "test_helper"

module Notey
  class CheckTest < ActiveSupport::TestCase
    setup { Rails.application.eager_load! }

    teardown { Notey.reset! }

    test "names the type and the notifier when a notifier names a type the catalog does not hold" do
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }

      error = assert_raises(Notey::UndeclaredType) { Notey.check! }

      assert_match(/MentionNotification.*mention/, error.message)
    end

    test "passes when every declared type and channel is delivered" do
      Notey.catalog do
        notification :comment, channels: %w[test recording], default: %w[test]
        notification :mention, channels: %w[test], default: %w[test]
      end

      assert_nothing_raised { Notey.check! }
    end

    test "forgets the notifiers when everything is reset" do
      registered = Notey.notifiers.dup
      notification_type_named(:invented)

      Notey.reset!

      assert_empty Notey.notifiers
    ensure
      registered.each { |notifier| Notey.register_notifier(notifier) }
    end

    test "forgets the notifiers it registered" do
      registered = Notey.notifiers.dup
      notification_type_named(:invented)

      Notey.forget_notifiers

      assert_empty Notey.notifiers
    ensure
      registered.each { |notifier| Notey.register_notifier(notifier) }
    end

    test "refuses a catalog with no sender address for its digests" do
      Notey.catalog do
        notification :comment, channels: %w[test recording], default: %w[test]
        notification :mention, channels: %w[test], default: %w[test]
      end
      previous = Notey.mailer_sender
      Notey.mailer_sender = nil

      error = assert_raises(Notey::MissingSender) { Notey.check! }

      assert_match(/mailer_sender/, error.message)
    ensure
      Notey.mailer_sender = previous
    end

    test "refuses a catalog channel nothing delivers on" do
      Notey.catalog do
        notification :comment, channels: %w[test carrier-pigeon], default: %w[test]
        notification :mention, channels: %w[test], default: %w[test]
      end

      error = assert_raises(Notey::UndeliverableChannel) { Notey.check! }

      assert_match(/carrier-pigeon/, error.message)
    end
  end
end
