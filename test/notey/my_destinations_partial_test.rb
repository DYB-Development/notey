# frozen_string_literal: true

require "test_helper"

module Notey
  class MyDestinationsPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

    teardown { Notey.reset! }

    test "asks for an address only on a channel that takes one" do
      Notey.catalog do
        notification :comment, channels: %w[email sms], default: []
        addressed :sms
      end

      render partial: "notey/my_destinations",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[name$='[address]']", 1
    end

    test "shows a person the address they set for a channel" do
      Notey.catalog do
        notification :comment, channels: %w[sms], default: []
        addressed :sms
      end
      member = Member.create!
      Destination.create!(account_id: 7, channel: "sms", member: member, address: "+15550001111")

      render partial: "notey/my_destinations",
        locals: { person: member, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[value='+15550001111']"
    end
  end
end
