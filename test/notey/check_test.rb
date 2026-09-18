# frozen_string_literal: true

require "test_helper"

module Notey
  class CheckTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "names the type and the notifier when a notifier names a type the catalog does not hold" do
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      MentionNotifier

      error = assert_raises(Notey::UndeclaredType) { Notey.check! }

      assert_match(/MentionNotifier.*mention/, error.message)
    end
  end
end
