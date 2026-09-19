# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationsLookupTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "takes the address a person stored over the account's" do
      member = Member.create!
      Destination.create!(account_id: 7, channel: "webhook", address: "https://account.example.com")
      Destination.create!(account_id: 7, channel: "webhook", member: member, address: "https://mine.example.com")

      found = Destinations.for(7, "webhook", member: member)

      assert_equal "https://mine.example.com", found.address
    end
  end
end
