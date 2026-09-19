# frozen_string_literal: true

require "test_helper"

module Notey
  class MyDestinationsPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

    teardown { Notey.reset! }

    test "shows a person the address they set for a channel" do
      Notey.catalog { notification :comment, channels: %w[sms], default: [] }
      member = Member.create!
      Destination.create!(account_id: 7, channel: "sms", member: member, address: "+15550001111")

      render partial: "notey/my_destinations",
        locals: { person: member, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[value='+15550001111']"
    end
  end
end
