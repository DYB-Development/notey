# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationsLookupTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "finds only what a person set for themselves" do
      member = Member.create!
      Destination.create!(account_id: 7, channel: "webhook", address: "https://account.example.com")

      found = Destinations.for(7, "webhook", member: member)

      assert_nil found
    end
  end
end
