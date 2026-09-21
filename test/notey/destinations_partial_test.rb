# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationsPartialTest < ActionView::TestCase
    helper KeystoneUiHelper
    helper Notey::ApplicationHelper

    teardown { Notey.reset! }

    setup { Notey.reset! }

    test "draws an address box for every channel that needs an address" do
      Notey.channel(:webhook, addressed: true)
      Notey.channel(:slack, addressed: true)
      Notey.channel(:plain)

      render partial: "notey/destinations",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[name$='[address]']", 2
    end

    test "shows the account's address and not a person's" do
      Notey.channel(:webhook, addressed: true)
      member = Member.create!
      Destination.create!(account_id: 7, channel: "webhook", member: member, address: "https://mine.example.com")

      render partial: "notey/destinations",
        locals: { person: member, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[value='https://mine.example.com']", false
    end
  end
end
