# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationsTest < ActionDispatch::IntegrationTest
    teardown do
      Current.reset
      Notey.reset!
    end

    def headers_for(member, account_id: 7)
      { "X-Member-Id" => member.id.to_s, "X-Account-Id" => account_id.to_s }
    end

    test "keeps an address an administrator set for a channel" do
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)

      patch "/notey/destinations",
        params: { destinations: { recording: { address: "https://x.example.com", credential: "sekrit" } } },
        headers: headers_for(Member.create!)

      assert_equal "https://x.example.com", Destination.last.address
    end

    test "keeps a stored credential when the box is left empty" do
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)
      Destination.create!(account_id: 7, channel: "recording",
        address: "https://x.example.com", credential: "sekrit")

      patch "/notey/destinations",
        params: { destinations: { recording: { address: "https://x.example.com", credential: "" } } },
        headers: headers_for(Member.create!)

      assert_equal "sekrit", Destination.last.credential
    end

    test "ignores a channel that needs no address" do
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)

      patch "/notey/destinations",
        params: { destinations: { carrier_pigeon: { address: "https://x.example.com" } } },
        headers: headers_for(Member.create!)

      assert_nil Destination.last
    end

    test "shows the page again when a destination does not save" do
      Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)

      patch "/notey/destinations",
        params: { destinations: { recording: { address: "" } } },
        headers: headers_for(Member.create!)

      assert_response :unprocessable_content
    end
  end
end
