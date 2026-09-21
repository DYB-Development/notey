# frozen_string_literal: true

require "test_helper"

module Notey
  class SaveDestinationTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "keeps the address an account set for a channel" do
      Notey.channel(:webhook, addressed: true)

      SaveDestination.new(person: Member.create!, account: 7,
        values: { destinations: { "webhook" => { "address" => "https://x.example.com" } } }).call

      assert_equal "https://x.example.com", Destination.last.address
    end

    test "keeps an address against the person who set it" do
      Notey.channel(:webhook, addressed: true)
      member = Member.create!

      SaveMyDestination.new(person: member, account: 7,
        values: { destinations: { "webhook" => { "address" => "https://mine.example.com" } } }).call

      assert_equal member, Destination.last.member
    end

    test "keeps a stored credential when the box is left empty" do
      Notey.channel(:webhook, addressed: true)
      Destination.create!(account_id: 7, channel: "webhook",
        address: "https://x.example.com", credential: "sekrit")

      SaveDestination.new(person: Member.create!, account: 7,
        values: { destinations: { "webhook" => { "address" => "https://x.example.com", "credential" => "" } } }).call

      assert_equal "sekrit", Destination.last.credential
    end
  end
end
