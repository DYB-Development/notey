# frozen_string_literal: true

require "test_helper"

module Notey
  class CheckTest < ActiveSupport::TestCase
    setup { Rails.application.eager_load! }

    teardown { Notey.reset! }

    test "passes when notey can send what it has to send" do
      assert_nothing_raised { Notey.check! }
    end

    test "forgets the notification types when everything is reset" do
      registered = Notey.notifiers.dup
      notification_type_named(:invented)

      Notey.reset!

      assert_empty Notey.notifiers
    ensure
      registered.each { |type| Notey.register_notifier(type) }
    end

    test "forgets the notification types it registered" do
      registered = Notey.notifiers.dup
      notification_type_named(:invented)

      Notey.forget_notifiers

      assert_empty Notey.notifiers
    ensure
      registered.each { |type| Notey.register_notifier(type) }
    end

    test "refuses to run with no sender address for its digests" do
      previous = Notey.mailer_sender
      Notey.mailer_sender = nil

      error = assert_raises(Notey::MissingSender) { Notey.check! }

      assert_match(/mailer_sender/, error.message)
    ensure
      Notey.mailer_sender = previous
    end

    test "refuses to run live updates with no url for a pushed row's Mark read" do
      Notey.live_updates = true

      error = assert_raises(Notey::MissingMarkReadUrl) { Notey.check! }

      assert_match(/mark_read_url/, error.message)
    end

    test "refuses to run live updates without Turbo loaded" do
      Notey.live_updates = true
      Notey.mark_read_url = ->(_notification) { "/notifications" }

      error = Notey.stub(:turbo_loaded?, false) do
        assert_raises(Notey::MissingTurbo) { Notey.check! }
      end

      assert_match(/turbo-rails/, error.message)
    end

    test "runs without Turbo while live updates are left off" do
      Notey.stub(:turbo_loaded?, false) do
        assert_nothing_raised { Notey.check! }
      end
    end
  end
end
