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
  end
end
