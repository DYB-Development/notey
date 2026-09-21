# frozen_string_literal: true

require "test_helper"

module Notey
  class DeclaredTypesTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "holds every notification type the notifiers declare" do
      Notey.forget_notifiers
      Notey.register_notifier(notification_type_named(:comment))
      Notey.register_notifier(notification_type_named(:mention))

      assert_equal %w[comment mention], Notey.notification_types.sort
    end
  end
end
