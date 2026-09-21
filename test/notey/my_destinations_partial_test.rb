# frozen_string_literal: true

require "test_helper"

module Notey
  class MyDestinationsPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

    setup { Notey.reset! }
    teardown { Notey.reset! }

    test "asks for an address only on a channel that takes one" do
      Notey.channel(:sms, addressed: true)

      render partial: "notey/my_destinations",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[name$='[address]']", 1
    end

    test "shows a person the address they set for a channel" do
      Notey.channel(:sms, addressed: true)
      member = Member.create!
      Destination.create!(account_id: 7, channel: "sms", member: member, address: "+15550001111")

      render partial: "notey/my_destinations",
        locals: { person: member, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[value='+15550001111']"
    end
  end
end
