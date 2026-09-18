# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationTest < ActiveSupport::TestCase
    teardown { Current.reset }

    test "keeps the credential out of the database in plain text" do
      Destination.create!(account_id: 7, channel: "webhook",
        address: "https://example.com/hook", credential: "sekrit")

      stored = Destination.connection.select_value("SELECT credential FROM notey_destinations LIMIT 1")

      assert_not_equal "sekrit", stored
    end
  end
end
