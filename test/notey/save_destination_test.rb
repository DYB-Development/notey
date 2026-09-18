# frozen_string_literal: true

require "test_helper"

module Notey
  class SaveDestinationTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "keeps the address an account set for a channel" do
      Notey.catalog { notification :comment, channels: %w[webhook], default: [] }

      SaveDestination.new(person: Member.create!, account: 7,
        values: { destinations: { "webhook" => { "address" => "https://x.example.com" } } }).call

      assert_equal "https://x.example.com", Destination.last.address
    end

    test "keeps a stored credential when the box is left empty" do
      Notey.catalog { notification :comment, channels: %w[webhook], default: [] }
      Destination.create!(account_id: 7, channel: "webhook",
        address: "https://x.example.com", credential: "sekrit")

      SaveDestination.new(person: Member.create!, account: 7,
        values: { destinations: { "webhook" => { "address" => "https://x.example.com", "credential" => "" } } }).call

      assert_equal "sekrit", Destination.last.credential
    end
  end
end
