# frozen_string_literal: true

require "test_helper"

module Notey
  class LiveInboxTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "gives two people in one account different streams" do
      first = Member.create!(email: "first@example.com")
      second = Member.create!(email: "second@example.com")

      assert_not_equal LiveInbox.stream(first, 7), LiveInbox.stream(second, 7)
    end
  end
end
